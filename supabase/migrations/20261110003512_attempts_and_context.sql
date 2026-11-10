-- Erros de negócio usam envelope para preservar a contabilização de tentativas.
create function private.failure(op text, code_ text, request_ uuid default null) returns jsonb
language sql volatile security invoker set search_path='' as $$
 select jsonb_strip_nulls(jsonb_build_object('operation',op,'request_id',request_,'server_time',clock_timestamp(),
 'code',code_,'retryable',code_ in ('RATE_LIMITED','TEMPORARILY_UNAVAILABLE'),
 'retry_after_ms',case when code_='RATE_LIMITED' then 6000 else null end,'correlation_id',gen_random_uuid()))
$$;
create function private.require_current_context(actor uuid, context_ uuid) returns void
language plpgsql volatile security invoker set search_path='' as $$
begin
 perform 1 from private.command_contexts where id=context_ and actor_id=actor and revoked_at is null
  and contract_version='1' and clock_timestamp()<expires_at;
 if not found then raise exception using message='REQUEST_EXPIRED',errcode='P0001'; end if;
end $$;

create or replace function public.ensure_profile(nickname text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid; name_ text:=btrim(nickname); code_ text; applied boolean:=false; attempts integer:=0;
begin
 begin
 actor:=private.require_actor();
 perform private.consume_rate(actor,'ensureProfile',10,60);
 exception when sqlstate 'P0001' then return private.failure('ensureProfile',sqlerrm,null);
 end;
 begin
 if name_ is null or char_length(name_) not between 2 and 24 then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
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
 exception when sqlstate 'P0001' then return private.failure('ensureProfile',sqlerrm,null);
 end;
end $$;

create or replace function public.get_my_profile() returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid; data_ jsonb;
begin
 begin
 actor:=private.require_actor();
 perform private.consume_rate(actor,'getMyProfile',120,60);
 exception when sqlstate 'P0001' then return private.failure('getMyProfile',sqlerrm,null);
 end;
 begin
 data_:=private.profile_data(actor);
 if data_ is null then raise exception using message='NOT_FOUND_OR_UNAVAILABLE',errcode='P0001'; end if;
 return private.reply('getMyProfile','unchanged',data_,jsonb_build_object('profile_revision',data_->>'revision',
  'preferences_revision',data_->'preferences'->>'revision'));
 exception when sqlstate 'P0001' then return private.failure('getMyProfile',sqlerrm,null);
 end;
end $$;

create or replace function public.get_command_context() returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid; row_ private.command_contexts%rowtype; at_ timestamptz;
begin
 begin
 actor:=private.require_actor();
 perform private.consume_rate(actor,'getCommandContext',10,60);
 exception when sqlstate 'P0001' then return private.failure('getCommandContext',sqlerrm,null);
 end;
 begin
 if not exists(select 1 from private.profiles where user_id=actor) then raise exception using message='NOT_FOUND_OR_UNAVAILABLE',errcode='P0001'; end if;
 at_:=clock_timestamp();
 insert into private.command_contexts(actor_id,issued_at,expires_at)
 values(actor,at_,at_+interval '15 minutes') returning * into row_;
 return private.reply('getCommandContext','applied',
  jsonb_build_object('command_context_id',row_.id,'contract_version',row_.contract_version,'issued_at',row_.issued_at,'expires_at',row_.expires_at),'{}');
 exception when sqlstate 'P0001' then return private.failure('getCommandContext',sqlerrm,null);
 end;
end $$;

create or replace function public.change_nickname(nickname text, expected_profile_revision bigint, command_context_id uuid, request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid; payload_ jsonb; replay jsonb; revision_ bigint; name_ text:=btrim(nickname);
begin
 begin
 actor:=private.require_actor();
 perform private.consume_rate(actor,'changeNickname',30,60);
 exception when sqlstate 'P0001' then return private.failure('changeNickname',sqlerrm,request_id);
 end;
 begin
 payload_:=jsonb_build_object('nickname',nickname,'expected_profile_revision',expected_profile_revision::text);
 replay:=private.start_command(actor,command_context_id,request_id,'changeNickname',payload_);
 if replay is not null then return replay; end if;
 if name_ is null or char_length(name_) not between 2 and 24 or expected_profile_revision is null or expected_profile_revision<0 then
  raise exception using message='INVALID_INPUT',errcode='P0001';
 end if;
 select revision into revision_ from private.profiles where user_id=actor for update;
 if not found then raise exception using message='NOT_FOUND_OR_UNAVAILABLE',errcode='P0001'; end if;
 perform private.require_current_context(actor,command_context_id);
 if revision_<>expected_profile_revision then raise exception using message='CONFLICT',errcode='P0001'; end if;
 update private.profiles set nickname=name_,revision=revision+1,updated_at=clock_timestamp() where user_id=actor returning revision into revision_;
 perform private.finish_command(actor,command_context_id,request_id,'changeNickname',payload_,revision_);
 return private.reply('changeNickname','applied',jsonb_build_object('nickname',name_),jsonb_build_object('profile_revision',revision_::text),request_id);
 exception when sqlstate 'P0001' then return private.failure('changeNickname',sqlerrm,request_id);
 end;
end $$;

create or replace function public.set_notification_preference(kind text, enabled boolean, expected_preferences_revision bigint, command_context_id uuid, request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid; payload_ jsonb; replay jsonb; revision_ bigint;
begin
 begin
 actor:=private.require_actor();
 perform private.consume_rate(actor,'setNotificationPreference',30,60);
 exception when sqlstate 'P0001' then return private.failure('setNotificationPreference',sqlerrm,request_id);
 end;
 begin
 payload_:=jsonb_build_object('kind',kind,'enabled',enabled,'expected_preferences_revision',expected_preferences_revision::text);
 replay:=private.start_command(actor,command_context_id,request_id,'setNotificationPreference',payload_);
 if replay is not null then return replay; end if;
 if kind is null or kind not in ('invites','friendships') or enabled is null or expected_preferences_revision is null or expected_preferences_revision<0 then
  raise exception using message='INVALID_INPUT',errcode='P0001';
 end if;
 select revision into revision_ from private.preferences where user_id=actor for update;
 if not found then raise exception using message='NOT_FOUND_OR_UNAVAILABLE',errcode='P0001'; end if;
 perform private.require_current_context(actor,command_context_id);
 if revision_<>expected_preferences_revision then raise exception using message='CONFLICT',errcode='P0001'; end if;
 update private.preferences set
  notify_invites=case when kind='invites' then enabled else notify_invites end,
  notify_friendships=case when kind='friendships' then enabled else notify_friendships end,
  revision=revision+1,updated_at=clock_timestamp() where user_id=actor returning revision into revision_;
 perform private.finish_command(actor,command_context_id,request_id,'setNotificationPreference',payload_,revision_);
 return private.reply('setNotificationPreference','applied',private.preferences_data(actor),jsonb_build_object('preferences_revision',revision_::text),request_id);
 exception when sqlstate 'P0001' then return private.failure('setNotificationPreference',sqlerrm,request_id);
 end;
end $$;

create or replace function public.save_message_preferences(p_position text, size_key text, speed_key text, expected_preferences_revision bigint, command_context_id uuid, request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid; payload_ jsonb; replay jsonb; revision_ bigint;
begin
 begin
 actor:=private.require_actor();
 perform private.consume_rate(actor,'saveMessagePreferences',30,60);
 exception when sqlstate 'P0001' then return private.failure('saveMessagePreferences',sqlerrm,request_id);
 end;
 begin
 payload_:=jsonb_build_object('position',p_position,'size_key',size_key,'speed_key',speed_key,'expected_preferences_revision',expected_preferences_revision::text);
 replay:=private.start_command(actor,command_context_id,request_id,'saveMessagePreferences',payload_);
 if replay is not null then return replay; end if;
 if p_position is null or p_position not in ('top','bottom') or size_key is null or size_key not in ('small','medium','large')
  or speed_key is null or speed_key not in ('slow','normal','fast') or expected_preferences_revision is null or expected_preferences_revision<0 then
  raise exception using message='INVALID_INPUT',errcode='P0001';
 end if;
 select revision into revision_ from private.preferences where user_id=actor for update;
 if not found then raise exception using message='NOT_FOUND_OR_UNAVAILABLE',errcode='P0001'; end if;
 perform private.require_current_context(actor,command_context_id);
 if revision_<>expected_preferences_revision then raise exception using message='CONFLICT',errcode='P0001'; end if;
 update private.preferences set overlay_position=p_position,overlay_size_key=size_key,overlay_speed_key=speed_key,
  revision=revision+1,updated_at=clock_timestamp() where user_id=actor returning revision into revision_;
 perform private.finish_command(actor,command_context_id,request_id,'saveMessagePreferences',payload_,revision_);
 return private.reply('saveMessagePreferences','applied',private.preferences_data(actor),jsonb_build_object('preferences_revision',revision_::text),request_id);
 exception when sqlstate 'P0001' then return private.failure('saveMessagePreferences',sqlerrm,request_id);
 end;
end $$;

revoke all on function private.failure(text,text,uuid),private.require_current_context(uuid,uuid) from public,anon,authenticated,service_role;
