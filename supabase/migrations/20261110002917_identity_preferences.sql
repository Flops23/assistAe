-- Identidade anônima Supabase e preferências. Todas as APIs são exclusivas de beta_testers.
create function private.require_actor() returns uuid
language plpgsql security invoker set search_path='' as $$
declare actor uuid:=auth.uid();
begin
 if actor is null then raise exception using message='UNAUTHENTICATED',errcode='P0001'; end if;
 -- Lock compartilhado define a autorização em relação à revogação concorrente do beta.
 perform 1 from private.beta_testers where user_id=actor and enabled for share;
 if not found then raise exception using message='FORBIDDEN',errcode='P0001'; end if;
 return actor;
end $$;

create function private.consume_rate(actor uuid, op text, capacity numeric, refill_seconds numeric) returns void
language plpgsql security invoker set search_path='' as $$
declare bucket private.rate_buckets%rowtype; current_time_ timestamptz; available numeric;
begin
 insert into private.rate_buckets(subject_key,operation,tokens) values(actor::text,op,capacity) on conflict do nothing;
 select * into strict bucket from private.rate_buckets where subject_key=actor::text and operation=op for update;
 current_time_:=clock_timestamp();
 available:=least(capacity,bucket.tokens+greatest(0,extract(epoch from current_time_-bucket.updated_at))*capacity/refill_seconds);
 if available<1 then raise exception using message='RATE_LIMITED',errcode='P0001'; end if;
 update private.rate_buckets set tokens=available-1,updated_at=current_time_ where subject_key=actor::text and operation=op;
end $$;

create function private.reply(op text, outcome_ text, data_ jsonb, revisions_ jsonb, request_id_ uuid default null) returns jsonb
language sql volatile security invoker set search_path='' as $$
 select jsonb_strip_nulls(jsonb_build_object(
 'operation',op,'request_id',request_id_,'server_time',clock_timestamp(),
 'outcome',outcome_,'data',data_,'revisions',revisions_))
$$;

create function private.preferences_data(actor uuid) returns jsonb
language sql stable security invoker set search_path='' as $$
 select jsonb_build_object('overlay_position',overlay_position,'overlay_size_key',overlay_size_key,
 'overlay_speed_key',overlay_speed_key,'notify_invites',notify_invites,'notify_friendships',notify_friendships,
 'revision',revision::text) from private.preferences where user_id=actor
$$;

create function private.profile_data(actor uuid) returns jsonb
language sql stable security invoker set search_path='' as $$
 select jsonb_build_object('user_id',user_id,'nickname',nickname,'public_code',public_code,
 'revision',revision::text,'preferences',private.preferences_data(actor)) from private.profiles where user_id=actor
$$;

create function private.start_command(actor uuid, context_ uuid, request_ uuid, operation_ text, payload_ jsonb) returns jsonb
language plpgsql security invoker set search_path='' as $$
declare receipt private.command_receipts%rowtype; context_row private.command_contexts%rowtype; digest_ text; revision_key text;
begin
 if context_ is null or request_ is null then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
 digest_:=encode(sha256(convert_to(jsonb_build_object('contract_version','1','context',context_,'operation',operation_,'payload',payload_)::text,'UTF8')),'hex');
 perform pg_advisory_xact_lock(hashtextextended('command:'||actor::text||':'||request_::text,0));
 select * into receipt from private.command_receipts where actor_id=actor and request_id=request_;
 if found then
  if receipt.command_context_id<>context_ or receipt.operation<>operation_ or receipt.payload_hash<>digest_ then
   raise exception using message='IDEMPOTENCY_MISMATCH',errcode='P0001';
  end if;
  revision_key:=case when operation_='changeNickname' then 'profile_revision' else 'preferences_revision' end;
  return private.reply(operation_,'already_applied',
   jsonb_build_object('result_code',receipt.result_code,'resource_id',receipt.resource_id),
   jsonb_build_object(revision_key,receipt.result_revision::text),request_);
 end if;
 select * into context_row from private.command_contexts where actor_id=actor and id=context_ for share;
 if not found or context_row.revoked_at is not null or context_row.contract_version<>'1' or clock_timestamp()>=context_row.expires_at then
  raise exception using message='REQUEST_EXPIRED',errcode='P0001';
 end if;
 return null;
end $$;

create function private.finish_command(actor uuid, context_ uuid, request_ uuid, operation_ text, payload_ jsonb, revision_ bigint) returns void
language sql volatile security invoker set search_path='' as $$
 insert into private.command_receipts(actor_id,request_id,command_context_id,operation,payload_hash,resource_id,result_code,result_revision,expires_at)
 select actor,request_,context_,operation_,
 encode(sha256(convert_to(jsonb_build_object('contract_version','1','context',context_,'operation',operation_,'payload',payload_)::text,'UTF8')),'hex'),
 actor,'OK',revision_,expires_at+interval '24 hours'
 from private.command_contexts where id=context_ and actor_id=actor
$$;

create function public.ensure_profile(nickname text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid; name_ text:=btrim(nickname); code_ text; applied boolean:=false; attempts integer:=0;
begin
 actor:=private.require_actor();
 if name_ is null or char_length(name_) not between 2 and 24 then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
 perform private.consume_rate(actor,'ensureProfile',10,60);
 perform pg_advisory_xact_lock(hashtextextended('profile:'||actor::text,0));
 if not exists(select 1 from private.profiles where user_id=actor) then
  loop
   code_:=upper(substr(replace(gen_random_uuid()::text,'-',''),1,12));
   begin
    insert into private.profiles(user_id,public_code,nickname) values(actor,code_,name_);
    exit;
   exception when unique_violation then
    attempts:=attempts+1;
    if attempts>=5 then raise exception using message='TEMPORARILY_UNAVAILABLE',errcode='P0001'; end if;
   end;
  end loop;
  applied:=true;
 end if;
 insert into private.preferences(user_id) values(actor) on conflict do nothing;
 return private.reply('ensureProfile',case when applied then 'applied' else 'unchanged' end,
  private.profile_data(actor),jsonb_build_object('profile_revision',(select revision::text from private.profiles where user_id=actor),
  'preferences_revision',(select revision::text from private.preferences where user_id=actor)));
end $$;

create function public.get_my_profile() returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid; data_ jsonb;
begin
 actor:=private.require_actor();
 perform private.consume_rate(actor,'getMyProfile',120,60);
 data_:=private.profile_data(actor);
 if data_ is null then raise exception using message='NOT_FOUND_OR_UNAVAILABLE',errcode='P0001'; end if;
 return private.reply('getMyProfile','unchanged',data_,jsonb_build_object('profile_revision',data_->>'revision',
  'preferences_revision',data_->'preferences'->>'revision'));
end $$;

create function public.get_command_context() returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid; row_ private.command_contexts%rowtype; at_ timestamptz;
begin
 actor:=private.require_actor();
 perform private.consume_rate(actor,'getCommandContext',10,60);
 if not exists(select 1 from private.profiles where user_id=actor) then raise exception using message='NOT_FOUND_OR_UNAVAILABLE',errcode='P0001'; end if;
 at_:=clock_timestamp();
 insert into private.command_contexts(actor_id,issued_at,expires_at)
 values(actor,at_,at_+interval '15 minutes') returning * into row_;
 return private.reply('getCommandContext','applied',
  jsonb_build_object('command_context_id',row_.id,'contract_version',row_.contract_version,'issued_at',row_.issued_at,'expires_at',row_.expires_at),'{}');
end $$;

create function public.change_nickname(nickname text, expected_profile_revision bigint, command_context_id uuid, request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid; payload_ jsonb; replay jsonb; revision_ bigint; name_ text:=btrim(nickname);
begin
 actor:=private.require_actor();
 perform private.consume_rate(actor,'changeNickname',30,60);
 payload_:=jsonb_build_object('nickname',nickname,'expected_profile_revision',expected_profile_revision::text);
 replay:=private.start_command(actor,command_context_id,request_id,'changeNickname',payload_);
 if replay is not null then return replay; end if;
 if name_ is null or char_length(name_) not between 2 and 24 or expected_profile_revision is null or expected_profile_revision<0 then
  raise exception using message='INVALID_INPUT',errcode='P0001';
 end if;
 select revision into revision_ from private.profiles where user_id=actor for update;
 if not found then raise exception using message='NOT_FOUND_OR_UNAVAILABLE',errcode='P0001'; end if;
 if revision_<>expected_profile_revision then raise exception using message='CONFLICT',errcode='P0001'; end if;
 update private.profiles set nickname=name_,revision=revision+1,updated_at=clock_timestamp() where user_id=actor returning revision into revision_;
 perform private.finish_command(actor,command_context_id,request_id,'changeNickname',payload_,revision_);
 return private.reply('changeNickname','applied',jsonb_build_object('nickname',name_),jsonb_build_object('profile_revision',revision_::text),request_id);
end $$;

create function public.set_notification_preference(kind text, enabled boolean, expected_preferences_revision bigint, command_context_id uuid, request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid; payload_ jsonb; replay jsonb; revision_ bigint;
begin
 actor:=private.require_actor();
 perform private.consume_rate(actor,'setNotificationPreference',30,60);
 payload_:=jsonb_build_object('kind',kind,'enabled',enabled,'expected_preferences_revision',expected_preferences_revision::text);
 replay:=private.start_command(actor,command_context_id,request_id,'setNotificationPreference',payload_);
 if replay is not null then return replay; end if;
 if kind is null or kind not in ('invites','friendships') or enabled is null or expected_preferences_revision is null or expected_preferences_revision<0 then
  raise exception using message='INVALID_INPUT',errcode='P0001';
 end if;
 select revision into revision_ from private.preferences where user_id=actor for update;
 if not found then raise exception using message='NOT_FOUND_OR_UNAVAILABLE',errcode='P0001'; end if;
 if revision_<>expected_preferences_revision then raise exception using message='CONFLICT',errcode='P0001'; end if;
 update private.preferences set
  notify_invites=case when kind='invites' then enabled else notify_invites end,
  notify_friendships=case when kind='friendships' then enabled else notify_friendships end,
  revision=revision+1,updated_at=clock_timestamp() where user_id=actor returning revision into revision_;
 perform private.finish_command(actor,command_context_id,request_id,'setNotificationPreference',payload_,revision_);
 return private.reply('setNotificationPreference','applied',private.preferences_data(actor),jsonb_build_object('preferences_revision',revision_::text),request_id);
end $$;

create function public.save_message_preferences(p_position text, size_key text, speed_key text, expected_preferences_revision bigint, command_context_id uuid, request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid; payload_ jsonb; replay jsonb; revision_ bigint;
begin
 actor:=private.require_actor();
 perform private.consume_rate(actor,'saveMessagePreferences',30,60);
 payload_:=jsonb_build_object('position',p_position,'size_key',size_key,'speed_key',speed_key,'expected_preferences_revision',expected_preferences_revision::text);
 replay:=private.start_command(actor,command_context_id,request_id,'saveMessagePreferences',payload_);
 if replay is not null then return replay; end if;
 if p_position is null or p_position not in ('top','bottom') or size_key is null or size_key not in ('small','medium','large')
  or speed_key is null or speed_key not in ('slow','normal','fast') or expected_preferences_revision is null or expected_preferences_revision<0 then
  raise exception using message='INVALID_INPUT',errcode='P0001';
 end if;
 select revision into revision_ from private.preferences where user_id=actor for update;
 if not found then raise exception using message='NOT_FOUND_OR_UNAVAILABLE',errcode='P0001'; end if;
 if revision_<>expected_preferences_revision then raise exception using message='CONFLICT',errcode='P0001'; end if;
 update private.preferences set overlay_position=p_position,overlay_size_key=size_key,overlay_speed_key=speed_key,
  revision=revision+1,updated_at=clock_timestamp() where user_id=actor returning revision into revision_;
 perform private.finish_command(actor,command_context_id,request_id,'saveMessagePreferences',payload_,revision_);
 return private.reply('saveMessagePreferences','applied',private.preferences_data(actor),jsonb_build_object('preferences_revision',revision_::text),request_id);
end $$;

revoke all on all functions in schema private from public,anon,authenticated,service_role;
revoke all on function public.ensure_profile(text),public.get_my_profile(),public.get_command_context(),
 public.change_nickname(text,bigint,uuid,uuid),public.set_notification_preference(text,boolean,bigint,uuid,uuid),
 public.save_message_preferences(text,text,text,bigint,uuid,uuid) from public,anon,service_role;
grant execute on function public.ensure_profile(text),public.get_my_profile(),public.get_command_context(),
 public.change_nickname(text,bigint,uuid,uuid),public.set_notification_preference(text,boolean,bigint,uuid,uuid),
 public.save_message_preferences(text,text,text,bigint,uuid,uuid) to authenticated;
