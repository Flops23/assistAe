-- Salas: papel específico, tabelas privadas e operações serializadas por perfil/sala.
create role assistae_room_api nologin noinherit nosuperuser nocreatedb nocreaterole noreplication nobypassrls;
grant assistae_room_api to postgres with inherit false, set true;
grant usage on schema public,private to assistae_room_api;
grant execute on function private.session_actor(),private.require_actor(),private.consume_rate(uuid,text,numeric,numeric),
 private.reply(text,text,jsonb,jsonb,uuid),private.start_command(uuid,uuid,uuid,text,jsonb),
 private.failure(text,text,uuid),private.require_current_context(uuid,uuid) to assistae_room_api;
grant select on private.profiles,private.beta_testers,private.command_contexts,private.command_receipts,private.rate_buckets to assistae_room_api;
grant update(revision) on private.profiles to assistae_room_api;
grant update(enabled) on private.beta_testers to assistae_room_api;
grant update(expires_at) on private.command_contexts to assistae_room_api;
grant insert on private.command_receipts,private.rate_buckets to assistae_room_api;
grant update on private.rate_buckets to assistae_room_api;
create policy room_profile_read on private.profiles for select to assistae_room_api using(true);
create policy room_profile_lock on private.profiles for update to assistae_room_api using(user_id=(select private.session_actor())) with check(false);
create policy room_beta_read on private.beta_testers for select to assistae_room_api using(user_id=(select private.session_actor()));
create policy room_beta_lock on private.beta_testers for update to assistae_room_api using(user_id=(select private.session_actor())) with check(false);
create policy room_context_read on private.command_contexts for select to assistae_room_api using(actor_id=(select private.session_actor()));
create policy room_context_lock on private.command_contexts for update to assistae_room_api using(actor_id=(select private.session_actor())) with check(false);
create policy room_receipt_read on private.command_receipts for select to assistae_room_api using(actor_id=(select private.session_actor()));
create policy room_receipt_insert on private.command_receipts for insert to assistae_room_api with check(actor_id=(select private.session_actor()));
create policy room_bucket on private.rate_buckets for all to assistae_room_api
 using(subject_key=(select private.session_actor())::text) with check(subject_key=(select private.session_actor())::text);
do $permissions$
declare t text;
begin
 foreach t in array array['rooms','room_codes','memberships','connections','room_bans','room_counters','chat_windows',
  'media_validations','media_items','playback','queue_items','messages','room_invites','notification_outbox'] loop
  execute format('grant select,insert,update,delete on private.%I to assistae_room_api',t);
  execute format('create policy room_internal_api on private.%I for all to assistae_room_api using(true) with check(true)',t);
 end loop;
end $permissions$;

create function private.close_room_internal(room_ uuid) returns void
language plpgsql security invoker set search_path='' as $$
declare now_ timestamptz:=clock_timestamp(); queued boolean;
begin
 select exists(select 1 from private.queue_items where room_id=room_) into queued;
 update private.rooms set status='closed',admin_state='none',admin_membership_id=null,closed_at=now_,revision=revision+1
  where id=room_ and status='active';
 if not found then return; end if;
 update private.memberships set state='ended',ended_at=now_,end_reason='room_closed' where room_id=room_ and state<>'ended';
 update private.chat_windows w set end_at_seq=c.last_message_seq from private.room_counters c
  where w.room_id=room_ and c.room_id=room_ and w.end_at_seq is null;
 update private.playback set status='empty',media_id=null,position_ms=0,reference_at=now_,media_epoch=media_epoch+1,revision=revision+1 where room_id=room_;
 delete from private.queue_items where room_id=room_;
 if queued then update private.room_counters set queue_revision=queue_revision+1 where room_id=room_; end if;
 delete from private.messages where room_id=room_;
 delete from private.media_items where room_id=room_;
 delete from private.media_validations where room_id=room_;
 update private.room_codes set invalidated_at=now_ where room_id=room_ and invalidated_at is null;
 update private.notification_outbox set status='suppressed',lease_until=null,attempt_token=null
  where status in ('pending','leased') and kind='invite' and resource_id in (select id from private.room_invites where room_id=room_);
 update private.room_invites set status='room_closed' where room_id=room_ and status='pending';
 delete from private.room_bans where room_id=room_;
end $$;

create function private.reconcile_room(room_ uuid) returns void
language plpgsql security invoker set search_path='' as $$
declare room_row private.rooms%rowtype; m record; at_ timestamptz; changed boolean:=false; successor uuid;
begin
 select * into room_row from private.rooms where id=room_ for update;
 if not found or room_row.status='closed' then return; end if;
 at_:=clock_timestamp();
 for m in select mm.id,mm.state,c.detected_at,c.suspect_at,c.grace_deadline from private.memberships mm
  join private.connections c on c.membership_id=mm.id where mm.room_id=room_ and mm.state<>'ended' loop
  if m.detected_at is null and at_>=m.suspect_at then
   update private.connections set detected_at=suspect_at,detection_source='silence' where membership_id=m.id;
  end if;
  if at_>=m.grace_deadline then
   update private.memberships set state='ended',ended_at=at_,end_reason='lease_expired' where id=m.id;
   changed:=true;
  elsif m.state='active' and (m.detected_at is not null or at_>=m.suspect_at) then
   update private.memberships set state='grace' where id=m.id;
   changed:=true;
  end if;
  if at_>=m.grace_deadline or m.detected_at is not null or at_>=m.suspect_at then
   update private.chat_windows w set end_at_seq=c.last_message_seq from private.room_counters c
    where w.membership_id=m.id and w.end_at_seq is null and c.room_id=room_;
  end if;
 end loop;
 if not exists(select 1 from private.memberships where room_id=room_ and state<>'ended') then
  perform private.close_room_internal(room_);
  return;
 end if;
 if room_row.admin_membership_id is null or not exists(select 1 from private.memberships where id=room_row.admin_membership_id and state<>'ended') then
  select mm.id into successor from private.memberships mm join private.connections c on c.membership_id=mm.id
   where mm.room_id=room_ and mm.state='active' and c.detected_at is null and c.suspect_at>at_
   order by mm.join_order,mm.id limit 1;
  if room_row.admin_membership_id is distinct from successor or room_row.admin_state is distinct from
   (case when successor is null then 'awaiting_successor' else 'assigned' end) then
   update private.rooms set admin_membership_id=successor,admin_state=case when successor is null then 'awaiting_successor' else 'assigned' end where id=room_;
   changed:=true;
  end if;
 end if;
 if changed then update private.rooms set revision=greatest(revision,room_row.revision+1) where id=room_; end if;
end $$;

create function private.require_live(actor uuid,room_ uuid,member_ uuid,generation_ bigint,gate text default 'live') returns void
language plpgsql security invoker set search_path='' as $$
declare r record; at_ timestamptz:=clock_timestamp();
begin
 select m.state,m.can_control,c.generation,c.detected_at,c.suspect_at,c.grace_deadline,rr.status,rr.admin_membership_id into r
  from private.memberships m join private.connections c on c.membership_id=m.id join private.rooms rr on rr.id=m.room_id
  where m.id=member_ and m.room_id=room_ and m.user_id=actor;
 if not found then raise exception using message='NOT_FOUND_OR_UNAVAILABLE',errcode='P0001'; end if;
 if r.status='closed' then raise exception using message='CLOSED',errcode='P0001'; end if;
 if r.state='ended' or at_>=r.grace_deadline then raise exception using message='REJOIN_REQUIRED',errcode='P0001'; end if;
 if generation_ is null or generation_<>r.generation then raise exception using message='STALE_CONNECTION',errcode='P0001'; end if;
 if r.state<>'active' or r.detected_at is not null or at_>=r.suspect_at then raise exception using message='RECONNECT_REQUIRED',errcode='P0001'; end if;
 if gate='admin' and r.admin_membership_id is distinct from member_ then raise exception using message='FORBIDDEN',errcode='P0001'; end if;
 if gate='control' and not(r.can_control or r.admin_membership_id is not distinct from member_) then raise exception using message='FORBIDDEN',errcode='P0001'; end if;
end $$;

create function private.admission(member_ uuid) returns jsonb
language sql stable security invoker set search_path='' as $$
 select jsonb_build_object('room_id',m.room_id,'membership_id',m.id,'generation',c.generation::text,
  'chat_window_id',w.id,'chat_start_after_seq',w.start_after_seq::text,'grace_deadline',c.grace_deadline)
 from private.memberships m join private.connections c on c.membership_id=m.id
 join private.chat_windows w on w.membership_id=m.id and w.end_at_seq is null and w.generation=c.generation
 where m.id=member_ and m.state='active'
$$;

create function private.admit_member(actor uuid,room_ uuid,member_ uuid) returns void
language plpgsql security invoker set search_path='' as $$
declare seq_ bigint; order_ bigint; at_ timestamptz:=clock_timestamp();
begin
 update private.room_counters set last_join_order=last_join_order+1 where room_id=room_ returning last_join_order,last_message_seq into order_,seq_;
 insert into private.memberships(id,room_id,user_id,join_order) values(member_,room_,actor,order_);
 insert into private.connections(membership_id,last_seen_at,suspect_at,grace_deadline) values(member_,at_,at_+interval '25 seconds',at_+interval '85 seconds');
 insert into private.chat_windows(room_id,membership_id,generation,start_after_seq) values(room_,member_,1,seq_);
end $$;

create function private.finish_room_command(actor uuid,context_ uuid,request_ uuid,op text,payload_ jsonb,room_ uuid) returns void
language sql volatile security invoker set search_path='' as $$
 insert into private.command_receipts(actor_id,request_id,command_context_id,operation,payload_hash,resource_id,result_code,result_revision,expires_at)
 select actor,request_,context_,op,encode(sha256(convert_to(jsonb_build_object('contract_version','1','context',context_,'operation',op,'payload',payload_)::text,'UTF8')),'hex'),
 room_,'OK',(select revision from private.rooms where id=room_),expires_at+interval '24 hours'
 from private.command_contexts where id=context_ and actor_id=actor
$$;

create or replace function private.start_command(actor uuid, context_ uuid, request_ uuid, operation_ text, payload_ jsonb) returns jsonb
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
  revision_key:=case when operation_='changeNickname' then 'profile_revision' when operation_ in ('setNotificationPreference','saveMessagePreferences') then 'preferences_revision' else 'room_revision' end;
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
create function public.create_room(name text, is_public boolean default true, command_context_id uuid default null, request_id uuid default null) returns jsonb
language plpgsql security definer set search_path='' as $fn$
#variable_conflict use_column
declare actor uuid; payload_ jsonb; replay_ jsonb; room_ uuid; member_ uuid; old_room uuid; base_revision bigint;
 row_ record; at_ timestamptz; data_ jsonb; req_ uuid; context_ uuid;
begin
 req_:=request_id; context_:=command_context_id;
 begin
  actor:=private.require_actor();
  perform private.consume_rate(actor,'createRoom',6,60);
 exception when sqlstate 'P0001' then return private.failure('createRoom',sqlerrm,req_); end;
 begin

 payload_:=jsonb_build_object('name',name,'public',is_public);
 replay_:=private.start_command(actor,context_,req_,'createRoom',payload_);
 if replay_ is not null then return replay_; end if;
 if name is null or char_length(btrim(name)) not between 2 and 60 or is_public is null then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
 perform 1 from private.profiles where user_id=actor for update;
 if not found then raise exception using message='NOT_FOUND_OR_UNAVAILABLE',errcode='P0001'; end if;
 select room_id into old_room from private.memberships where user_id=actor and state<>'ended';
 if old_room is not null then
  perform private.reconcile_room(old_room);
  if exists(select 1 from private.memberships where user_id=actor and state<>'ended') then raise exception using message='ALREADY_IN_ROOM',errcode='P0001'; end if;
 end if;
 perform private.require_current_context(actor,context_);
 room_:=gen_random_uuid(); member_:=gen_random_uuid();
 insert into private.rooms(id,name,visibility,admin_membership_id) values(room_,btrim(name),case when is_public then 'public' else 'private' end,member_);
 insert into private.room_counters(room_id) values(room_);
 insert into private.playback(room_id) values(room_);
 insert into private.room_codes(room_id,code) values(room_,upper(substr(replace(gen_random_uuid()::text,'-',''),1,12)));
 perform private.admit_member(actor,room_,member_);
 perform private.finish_room_command(actor,context_,req_,'createRoom',payload_,room_);
 return private.reply('createRoom','applied',private.admission(member_),jsonb_build_object('room_revision',(select revision::text from private.rooms where id=room_)),req_);

 exception when sqlstate 'P0001' then return private.failure('createRoom',sqlerrm,req_);
 when invalid_text_representation or numeric_value_out_of_range then return private.failure('createRoom','INVALID_INPUT',req_);
 end;
end $fn$;

create function public.join_room(target jsonb, command_context_id uuid, request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $fn$
#variable_conflict use_column
declare actor uuid; payload_ jsonb; replay_ jsonb; room_ uuid; member_ uuid; old_room uuid; base_revision bigint;
 row_ record; at_ timestamptz; data_ jsonb; req_ uuid; context_ uuid;
begin
 req_:=request_id; context_:=command_context_id;
 begin
  actor:=private.require_actor();
  perform private.consume_rate(actor,'joinRoom',20,60);
 exception when sqlstate 'P0001' then return private.failure('joinRoom',sqlerrm,req_); end;
 begin

 payload_:=jsonb_build_object('target',target);
 replay_:=private.start_command(actor,context_,req_,'joinRoom',payload_);
 if replay_ is not null then return replay_; end if;
 if target is null or jsonb_typeof(target)<>'object' or (select count(*) from jsonb_object_keys(target))<>1 or
  not(target ? 'code' or target ? 'public_room_id' or target ? 'invite_id') then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
 perform 1 from private.profiles where user_id=actor for update;
 if not found then raise exception using message='NOT_FOUND_OR_UNAVAILABLE',errcode='P0001'; end if;
 if target ? 'code' then
  select room_id into room_ from private.room_codes where code=upper(btrim(target->>'code')) and invalidated_at is null;
 elsif target ? 'public_room_id' then
  select id into room_ from private.rooms where id=(target->>'public_room_id')::uuid and visibility='public';
 else
  select room_id into room_ from private.room_invites where id=(target->>'invite_id')::uuid and recipient_id=actor and status='pending';
 end if;
 if room_ is null then raise exception using message='NOT_FOUND_OR_UNAVAILABLE',errcode='P0001'; end if;
 select room_id into old_room from private.memberships where user_id=actor and state<>'ended';
 perform 1 from private.rooms where id in (room_,old_room) order by id for update;
 select revision into base_revision from private.rooms where id=room_;
 if old_room is not null then perform private.reconcile_room(old_room); end if;
 perform private.reconcile_room(room_);
 perform private.require_current_context(actor,context_);
 if (select status from private.rooms where id=room_)='closed' then raise exception using message='CLOSED',errcode='P0001'; end if;
 if target ? 'invite_id' and not exists(select 1 from private.room_invites where id=(target->>'invite_id')::uuid and recipient_id=actor and room_id=room_ and status='pending') then raise exception using message='NOT_FOUND_OR_UNAVAILABLE',errcode='P0001'; end if;
 if exists(select 1 from private.room_bans where room_id=room_ and user_id=actor) then raise exception using message='FORBIDDEN',errcode='P0001'; end if;
 select id,room_id into row_ from private.memberships where user_id=actor and state<>'ended';
 if found then
  if row_.room_id<>room_ then raise exception using message='ALREADY_IN_ROOM',errcode='P0001'; end if;
  member_:=row_.id;
  perform private.require_live(actor,room_,member_,(select generation from private.connections where membership_id=member_));
  perform private.finish_room_command(actor,context_,req_,'joinRoom',payload_,room_);
  return private.reply('joinRoom','unchanged',private.admission(member_),jsonb_build_object('room_revision',(select revision::text from private.rooms where id=room_)),req_);
 end if;
 if (select count(*) from private.memberships where room_id=room_ and state<>'ended')>=10 then raise exception using message='ROOM_FULL',errcode='P0001'; end if;
 member_:=gen_random_uuid();
 perform private.admit_member(actor,room_,member_);
 if target ? 'invite_id' then update private.room_invites set status='used',used_at=clock_timestamp() where id=(target->>'invite_id')::uuid; end if;
 perform private.reconcile_room(room_);
 update private.rooms set revision=greatest(revision,base_revision+1) where id=room_;
 perform private.finish_room_command(actor,context_,req_,'joinRoom',payload_,room_);
 return private.reply('joinRoom','applied',private.admission(member_),jsonb_build_object('room_revision',(select revision::text from private.rooms where id=room_)),req_);

 exception when sqlstate 'P0001' then return private.failure('joinRoom',sqlerrm,req_);
 when invalid_text_representation or numeric_value_out_of_range then return private.failure('joinRoom','INVALID_INPUT',req_);
 end;
end $fn$;

create function public.get_room_code(room_id uuid, membership_id uuid, generation bigint) returns jsonb
language plpgsql security definer set search_path='' as $fn$
#variable_conflict use_column
declare actor uuid; payload_ jsonb; replay_ jsonb; room_ uuid; member_ uuid; old_room uuid; base_revision bigint;
 row_ record; at_ timestamptz; data_ jsonb; req_ uuid; context_ uuid;
begin

 begin
  actor:=private.require_actor();
  perform private.consume_rate(actor,'getRoomCode',30,60);
 exception when sqlstate 'P0001' then return private.failure('getRoomCode',sqlerrm,req_); end;
 begin

 room_:=room_id; member_:=membership_id;
 perform 1 from private.rooms where id=room_ for update;
 perform private.reconcile_room(room_);
 perform private.require_live(actor,room_,member_,generation);
 return private.reply('getRoomCode','unchanged',jsonb_build_object('code',(select code from private.room_codes where room_id=room_ and invalidated_at is null)),'{}');

 exception when sqlstate 'P0001' then return private.failure('getRoomCode',sqlerrm,req_);
 when invalid_text_representation or numeric_value_out_of_range then return private.failure('getRoomCode','INVALID_INPUT',req_);
 end;
end $fn$;

create function public.get_room_snapshot(room_id uuid, membership_id uuid, generation bigint) returns jsonb
language plpgsql security definer set search_path='' as $fn$
#variable_conflict use_column
declare actor uuid; payload_ jsonb; replay_ jsonb; room_ uuid; member_ uuid; old_room uuid; base_revision bigint;
 row_ record; at_ timestamptz; data_ jsonb; req_ uuid; context_ uuid;
begin

 begin
  actor:=private.require_actor();
  perform private.consume_rate(actor,'getRoomSnapshot',120,60);
 exception when sqlstate 'P0001' then return private.failure('getRoomSnapshot',sqlerrm,req_); end;
 begin

 room_:=room_id; member_:=membership_id;
 perform 1 from private.rooms where id=room_ for update;
 perform private.reconcile_room(room_);
 perform private.require_live(actor,room_,member_,generation);
 at_:=clock_timestamp();
 select jsonb_build_object('room_id',r.id,'name',r.name,'visibility',r.visibility,'status',r.status,
  'admin_state',r.admin_state,'admin_membership_id',r.admin_membership_id,
  'connected_count',(select count(*) from private.memberships m join private.connections c on c.membership_id=m.id
    where m.room_id=room_ and m.state='active' and c.detected_at is null and c.suspect_at>at_),
  'participants',(select coalesce(jsonb_agg(jsonb_build_object('membership_id',m.id,'user_id',m.user_id,'nickname',p.nickname,'state',m.state,'can_control',m.can_control) order by m.join_order),'[]')
   from private.memberships m join private.profiles p on p.user_id=m.user_id where m.room_id=room_ and m.state<>'ended'),
  'playback',(select jsonb_build_object('media_id',pb.media_id,'media_epoch',pb.media_epoch::text,'status',pb.status,'position_ms',pb.position_ms::text,'reference_at',pb.reference_at,
    'source_url',mi.source_url,'kind',mi.kind,'duration_ms',mi.duration_ms::text,'duration_confidence',mi.duration_confidence,
    'termination_mode',case when mi.id is null then null when mi.duration_confidence='verified' then 'server_timeline' else 'authorized_manual' end,
    'expected_end_at',case when pb.status='playing' and mi.duration_confidence='verified' then pb.reference_at+(greatest(0,mi.duration_ms-pb.position_ms)::double precision/1000)*interval '1 second' else null end)
   from private.playback pb left join private.media_items mi on mi.room_id=pb.room_id and mi.id=pb.media_id where pb.room_id=room_),
  'queue',(select coalesce(jsonb_agg(jsonb_build_object('id',q.id,'position',q.position,'media_id',mi.id,'title',mi.title,'source_url',mi.source_url,'kind',mi.kind) order by q.position),'[]')
   from private.queue_items q join private.media_items mi on mi.id=q.media_id and mi.room_id=q.room_id where q.room_id=room_),
  'admission',private.admission(member_)) into data_ from private.rooms r where r.id=room_;
 return private.reply('getRoomSnapshot','unchanged',data_,jsonb_build_object('room_revision',(select revision::text from private.rooms where id=room_),
 'playback_revision',(select revision::text from private.playback where room_id=room_),'queue_revision',(select queue_revision::text from private.room_counters where room_id=room_)));

 exception when sqlstate 'P0001' then return private.failure('getRoomSnapshot',sqlerrm,req_);
 when invalid_text_representation or numeric_value_out_of_range then return private.failure('getRoomSnapshot','INVALID_INPUT',req_);
 end;
end $fn$;

create function public.heartbeat(room_id uuid, membership_id uuid, generation bigint, heartbeat_seq bigint) returns jsonb
language plpgsql security definer set search_path='' as $fn$
#variable_conflict use_column
declare actor uuid; payload_ jsonb; replay_ jsonb; room_ uuid; member_ uuid; old_room uuid; base_revision bigint;
 row_ record; at_ timestamptz; data_ jsonb; req_ uuid; context_ uuid;
begin

 begin
  actor:=private.require_actor();
  perform private.consume_rate(actor,'heartbeat',120,60);
 exception when sqlstate 'P0001' then return private.failure('heartbeat',sqlerrm,req_); end;
 begin

 room_:=room_id; member_:=membership_id;
 if heartbeat_seq is null or heartbeat_seq<1 then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
 perform 1 from private.rooms where id=room_ for update;
 perform private.reconcile_room(room_);
 perform private.require_live(actor,room_,member_,generation);
 select last_heartbeat_seq into base_revision from private.connections where membership_id=member_;
 if heartbeat_seq<=base_revision then return private.reply('heartbeat','unchanged',jsonb_build_object('generation',generation::text),'{}'); end if;
 at_:=clock_timestamp();
 update private.connections set last_heartbeat_seq=heartbeat_seq,last_seen_at=at_,suspect_at=at_+interval '25 seconds',grace_deadline=at_+interval '85 seconds' where membership_id=member_;
 return private.reply('heartbeat','applied',jsonb_build_object('generation',generation::text,'grace_deadline',at_+interval '85 seconds'),'{}');

 exception when sqlstate 'P0001' then return private.failure('heartbeat',sqlerrm,req_);
 when invalid_text_representation or numeric_value_out_of_range then return private.failure('heartbeat','INVALID_INPUT',req_);
 end;
end $fn$;

create function public.reconnect_room(room_id uuid, membership_id uuid, expected_generation bigint, command_context_id uuid, request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $fn$
#variable_conflict use_column
declare actor uuid; payload_ jsonb; replay_ jsonb; room_ uuid; member_ uuid; old_room uuid; base_revision bigint;
 row_ record; at_ timestamptz; data_ jsonb; req_ uuid; context_ uuid;
begin
 req_:=request_id; context_:=command_context_id;
 begin
  actor:=private.require_actor();
  perform private.consume_rate(actor,'reconnectRoom',30,60);
 exception when sqlstate 'P0001' then return private.failure('reconnectRoom',sqlerrm,req_); end;
 begin

 room_:=room_id; member_:=membership_id;
 payload_:=jsonb_build_object('room_id',room_,'membership_id',member_,'expected_generation',expected_generation::text);
 replay_:=private.start_command(actor,context_,req_,'reconnectRoom',payload_);
 perform 1 from private.rooms where id=room_ for update;
 if replay_ is not null then
  if exists(select 1 from private.memberships m join private.connections c on c.membership_id=m.id join private.rooms r on r.id=m.room_id
   where m.id=member_ and m.room_id=room_ and m.user_id=actor and m.state='active' and r.status='active' and c.generation-1=expected_generation and c.detected_at is null and c.suspect_at>clock_timestamp()) then
   return private.reply('reconnectRoom','already_applied',private.admission(member_),replay_->'revisions',req_);
  end if;
  return replay_;
 end if;
 select revision into base_revision from private.rooms where id=room_;
 perform private.reconcile_room(room_);
 select m.state,c.generation,c.grace_deadline,r.status into row_ from private.memberships m
  join private.connections c on c.membership_id=m.id join private.rooms r on r.id=m.room_id
  where m.id=member_ and m.room_id=room_ and m.user_id=actor;
 if not found then raise exception using message='NOT_FOUND_OR_UNAVAILABLE',errcode='P0001'; end if;
 if row_.status='closed' then raise exception using message='CLOSED',errcode='P0001'; end if;
 if row_.state='ended' or clock_timestamp()>=row_.grace_deadline then raise exception using message='REJOIN_REQUIRED',errcode='P0001'; end if;
 if expected_generation is null or expected_generation<>row_.generation then raise exception using message='STALE_CONNECTION',errcode='P0001'; end if;
 perform private.require_current_context(actor,context_);
 at_:=clock_timestamp();
 update private.chat_windows w set end_at_seq=c.last_message_seq from private.room_counters c where w.membership_id=member_ and w.end_at_seq is null and c.room_id=room_;
 update private.connections set generation=connections.generation+1,last_heartbeat_seq=0,last_seen_at=at_,suspect_at=at_+interval '25 seconds',
  grace_deadline=at_+interval '85 seconds',detected_at=null,detection_source=null where connections.membership_id=member_;
 update private.memberships set state='active' where id=member_;
 insert into private.chat_windows(room_id,membership_id,generation,start_after_seq)
 select room_,member_,c.generation,rc.last_message_seq from private.connections c cross join private.room_counters rc where c.membership_id=member_ and rc.room_id=room_;
 perform private.reconcile_room(room_);
 update private.rooms set revision=greatest(revision,base_revision+1) where id=room_;
 perform private.finish_room_command(actor,context_,req_,'reconnectRoom',payload_,room_);
 return private.reply('reconnectRoom','applied',private.admission(member_),jsonb_build_object('room_revision',(select revision::text from private.rooms where id=room_)),req_);

 exception when sqlstate 'P0001' then return private.failure('reconnectRoom',sqlerrm,req_);
 when invalid_text_representation or numeric_value_out_of_range then return private.failure('reconnectRoom','INVALID_INPUT',req_);
 end;
end $fn$;

create function public.get_my_participation() returns jsonb
language plpgsql security definer set search_path='' as $fn$
#variable_conflict use_column
declare actor uuid; payload_ jsonb; replay_ jsonb; room_ uuid; member_ uuid; old_room uuid; base_revision bigint;
 row_ record; at_ timestamptz; data_ jsonb; req_ uuid; context_ uuid;
begin

 begin
  actor:=private.require_actor();
  perform private.consume_rate(actor,'getMyParticipation',120,60);
 exception when sqlstate 'P0001' then return private.failure('getMyParticipation',sqlerrm,req_); end;
 begin

 select room_id into room_ from private.memberships where user_id=actor and state<>'ended';
 if room_ is null then return private.reply('getMyParticipation','unchanged','null'::jsonb,'{}'); end if;
 perform private.reconcile_room(room_);
 select jsonb_build_object('room_id',m.room_id,'membership_id',m.id,'generation',c.generation::text,
  'phase',case when c.detected_at is null and c.suspect_at>clock_timestamp() then 'active' else 'grace' end,'grace_deadline',c.grace_deadline) into data_
 from private.memberships m join private.connections c on c.membership_id=m.id where m.user_id=actor and m.state<>'ended';
 return private.reply('getMyParticipation','unchanged',data_,jsonb_build_object('room_revision',(select revision::text from private.rooms where id=room_)));

 exception when sqlstate 'P0001' then return private.failure('getMyParticipation',sqlerrm,req_);
 when invalid_text_representation or numeric_value_out_of_range then return private.failure('getMyParticipation','INVALID_INPUT',req_);
 end;
end $fn$;

create function public.leave_room(room_id uuid, membership_id uuid, generation bigint, successor_membership_id uuid, expected_room_revision bigint, command_context_id uuid, request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $fn$
#variable_conflict use_column
declare actor uuid; payload_ jsonb; replay_ jsonb; room_ uuid; member_ uuid; old_room uuid; base_revision bigint;
 row_ record; at_ timestamptz; data_ jsonb; req_ uuid; context_ uuid;
begin
 req_:=request_id; context_:=command_context_id;
 begin
  actor:=private.require_actor();
  perform private.consume_rate(actor,'leaveRoom',30,60);
 exception when sqlstate 'P0001' then return private.failure('leaveRoom',sqlerrm,req_); end;
 begin

 room_:=room_id; member_:=membership_id;
 payload_:=jsonb_build_object('room_id',room_,'membership_id',member_,'generation',generation::text,'successor_membership_id',successor_membership_id,'expected_room_revision',expected_room_revision::text);
 replay_:=private.start_command(actor,context_,req_,'leaveRoom',payload_);
 if replay_ is not null then return replay_; end if;
 perform 1 from private.rooms where id=room_ for update;
 select revision into base_revision from private.rooms where id=room_;
 perform private.reconcile_room(room_);
 select m.state,c.generation,r.admin_membership_id,r.revision into row_ from private.memberships m join private.connections c on c.membership_id=m.id join private.rooms r on r.id=m.room_id
 where m.id=member_ and m.room_id=room_ and m.user_id=actor;
 if not found then raise exception using message='NOT_FOUND_OR_UNAVAILABLE',errcode='P0001'; end if;
 if generation is null or generation<>row_.generation then raise exception using message='STALE_CONNECTION',errcode='P0001'; end if;
 perform private.require_current_context(actor,context_);
 if successor_membership_id is not null then
  if row_.admin_membership_id is distinct from member_ then raise exception using message='FORBIDDEN',errcode='P0001'; end if;
  if expected_room_revision is null or expected_room_revision<>row_.revision then raise exception using message='CONFLICT',errcode='P0001'; end if;
  if successor_membership_id=member_ or not exists(select 1 from private.memberships m join private.connections c on c.membership_id=m.id
    where m.id=successor_membership_id and m.room_id=room_ and m.state='active' and c.detected_at is null and c.suspect_at>clock_timestamp()) then raise exception using message='CONFLICT',errcode='P0001'; end if;
  update private.rooms set admin_membership_id=successor_membership_id where id=room_;
 end if;
 if row_.state<>'ended' then
  update private.memberships set state='ended',ended_at=clock_timestamp(),end_reason='left' where id=member_;
  update private.chat_windows w set end_at_seq=c.last_message_seq from private.room_counters c where w.membership_id=member_ and w.end_at_seq is null and c.room_id=room_;
  perform private.reconcile_room(room_);
  update private.rooms set revision=greatest(revision,base_revision+1) where id=room_;
 end if;
 perform private.finish_room_command(actor,context_,req_,'leaveRoom',payload_,room_);
 return private.reply('leaveRoom','applied',jsonb_build_object('room_id',room_),jsonb_build_object('room_revision',(select revision::text from private.rooms where id=room_)),req_);

 exception when sqlstate 'P0001' then return private.failure('leaveRoom',sqlerrm,req_);
 when invalid_text_representation or numeric_value_out_of_range then return private.failure('leaveRoom','INVALID_INPUT',req_);
 end;
end $fn$;

create function public.close_room(room_id uuid, membership_id uuid, generation bigint, expected_room_revision bigint, command_context_id uuid, request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $fn$
#variable_conflict use_column
declare actor uuid; payload_ jsonb; replay_ jsonb; room_ uuid; member_ uuid; old_room uuid; base_revision bigint;
 row_ record; at_ timestamptz; data_ jsonb; req_ uuid; context_ uuid;
begin
 req_:=request_id; context_:=command_context_id;
 begin
  actor:=private.require_actor();
  perform private.consume_rate(actor,'closeRoom',30,60);
 exception when sqlstate 'P0001' then return private.failure('closeRoom',sqlerrm,req_); end;
 begin

 room_:=room_id; member_:=membership_id;
 payload_:=jsonb_build_object('room_id',room_,'membership_id',member_,'generation',generation::text,'expected_room_revision',expected_room_revision::text);
 replay_:=private.start_command(actor,context_,req_,'closeRoom',payload_);
 if replay_ is not null then return replay_; end if;
 perform 1 from private.rooms where id=room_ for update;
 select revision into base_revision from private.rooms where id=room_;
 perform private.reconcile_room(room_);
 perform private.require_live(actor,room_,member_,generation,'admin');
 if expected_room_revision is null or expected_room_revision<>(select revision from private.rooms where id=room_) then raise exception using message='CONFLICT',errcode='P0001'; end if;
 perform private.require_current_context(actor,context_);
 perform private.close_room_internal(room_);
 update private.rooms set revision=base_revision+1 where id=room_;
 perform private.finish_room_command(actor,context_,req_,'closeRoom',payload_,room_);
 return private.reply('closeRoom','applied',jsonb_build_object('room_id',room_),jsonb_build_object('room_revision',(select revision::text from private.rooms where id=room_)),req_);

 exception when sqlstate 'P0001' then return private.failure('closeRoom',sqlerrm,req_);
 when invalid_text_representation or numeric_value_out_of_range then return private.failure('closeRoom','INVALID_INPUT',req_);
 end;
end $fn$;
create or replace function private.reply(op text, outcome_ text, data_ jsonb, revisions_ jsonb, request_id_ uuid default null) returns jsonb
language sql volatile security invoker set search_path='' as $$
 select jsonb_build_object('operation',op,'server_time',clock_timestamp(),'outcome',outcome_,'data',data_,'revisions',revisions_) ||
 case when request_id_ is null then '{}'::jsonb else jsonb_build_object('request_id',request_id_) end
$$;

create function private.expire_rooms(batch_limit integer default 100) returns integer
language plpgsql security definer set search_path='' as $$
declare room_ record; count_ integer:=0;
begin
 if batch_limit is null or batch_limit not between 1 and 1000 then raise exception 'INVALID_INPUT'; end if;
 for room_ in select r.id from private.rooms r where r.status='active' and exists(
  select 1 from private.memberships m join private.connections c on c.membership_id=m.id where m.room_id=r.id and m.state<>'ended'
  and (c.grace_deadline<=clock_timestamp() or (m.state='active' and (c.detected_at is not null or c.suspect_at<=clock_timestamp()))))
  order by r.id limit batch_limit for update of r skip locked loop
  perform private.reconcile_room(room_.id); count_:=count_+1;
 end loop;
 return count_;
end $$;

grant execute on function private.close_room_internal(uuid),private.reconcile_room(uuid),private.require_live(uuid,uuid,uuid,bigint,text),
private.admission(uuid),private.admit_member(uuid,uuid,uuid),private.finish_room_command(uuid,uuid,uuid,text,jsonb,uuid) to assistae_room_api;
grant create on schema public,private to assistae_room_api;
revoke all on function public.create_room(text,boolean,uuid,uuid) from public,anon,service_role;
grant execute on function public.create_room(text,boolean,uuid,uuid) to authenticated;
alter function public.create_room(text,boolean,uuid,uuid) owner to assistae_room_api;
revoke all on function public.join_room(jsonb,uuid,uuid) from public,anon,service_role;
grant execute on function public.join_room(jsonb,uuid,uuid) to authenticated;
alter function public.join_room(jsonb,uuid,uuid) owner to assistae_room_api;
revoke all on function public.get_room_code(uuid,uuid,bigint) from public,anon,service_role;
grant execute on function public.get_room_code(uuid,uuid,bigint) to authenticated;
alter function public.get_room_code(uuid,uuid,bigint) owner to assistae_room_api;
revoke all on function public.get_room_snapshot(uuid,uuid,bigint) from public,anon,service_role;
grant execute on function public.get_room_snapshot(uuid,uuid,bigint) to authenticated;
alter function public.get_room_snapshot(uuid,uuid,bigint) owner to assistae_room_api;
revoke all on function public.heartbeat(uuid,uuid,bigint,bigint) from public,anon,service_role;
grant execute on function public.heartbeat(uuid,uuid,bigint,bigint) to authenticated;
alter function public.heartbeat(uuid,uuid,bigint,bigint) owner to assistae_room_api;
revoke all on function public.reconnect_room(uuid,uuid,bigint,uuid,uuid) from public,anon,service_role;
grant execute on function public.reconnect_room(uuid,uuid,bigint,uuid,uuid) to authenticated;
alter function public.reconnect_room(uuid,uuid,bigint,uuid,uuid) owner to assistae_room_api;
revoke all on function public.get_my_participation() from public,anon,service_role;
grant execute on function public.get_my_participation() to authenticated;
alter function public.get_my_participation() owner to assistae_room_api;
revoke all on function public.leave_room(uuid,uuid,bigint,uuid,bigint,uuid,uuid) from public,anon,service_role;
grant execute on function public.leave_room(uuid,uuid,bigint,uuid,bigint,uuid,uuid) to authenticated;
alter function public.leave_room(uuid,uuid,bigint,uuid,bigint,uuid,uuid) owner to assistae_room_api;
revoke all on function public.close_room(uuid,uuid,bigint,bigint,uuid,uuid) from public,anon,service_role;
grant execute on function public.close_room(uuid,uuid,bigint,bigint,uuid,uuid) to authenticated;
alter function public.close_room(uuid,uuid,bigint,bigint,uuid,uuid) owner to assistae_room_api;
revoke all on function private.expire_rooms(integer) from public,anon,authenticated,service_role;
grant execute on function private.expire_rooms(integer) to postgres;
alter function private.expire_rooms(integer) owner to assistae_room_api;
revoke create on schema public,private from assistae_room_api;
