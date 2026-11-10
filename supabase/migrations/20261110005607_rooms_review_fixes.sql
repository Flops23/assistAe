grant create on schema public to assistae_room_api;
set local role assistae_room_api;

create or replace function public.join_room(target jsonb, command_context_id uuid, request_id uuid) returns jsonb
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
 if target is null or jsonb_typeof(target)<>'object' then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
 if (select count(*) from jsonb_object_keys(target))<>1 or
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
 update private.rooms set revision=base_revision+1 where id=room_;
 perform private.finish_room_command(actor,context_,req_,'joinRoom',payload_,room_);
 return private.reply('joinRoom','applied',private.admission(member_),jsonb_build_object('room_revision',(select revision::text from private.rooms where id=room_)),req_);

 exception when sqlstate 'P0001' then return private.failure('joinRoom',sqlerrm,req_);
 when invalid_text_representation or numeric_value_out_of_range then return private.failure('joinRoom','INVALID_INPUT',req_);
 end;
end $fn$;

create or replace function public.reconnect_room(room_id uuid, membership_id uuid, expected_generation bigint, command_context_id uuid, request_id uuid) returns jsonb
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
 update private.rooms set revision=base_revision+1 where id=room_;
 perform private.finish_room_command(actor,context_,req_,'reconnectRoom',payload_,room_);
 return private.reply('reconnectRoom','applied',private.admission(member_),jsonb_build_object('room_revision',(select revision::text from private.rooms where id=room_)),req_);

 exception when sqlstate 'P0001' then return private.failure('reconnectRoom',sqlerrm,req_);
 when invalid_text_representation or numeric_value_out_of_range then return private.failure('reconnectRoom','INVALID_INPUT',req_);
 end;
end $fn$;

create or replace function public.get_my_participation() returns jsonb
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

 perform 1 from private.profiles where user_id=actor for update;
 select room_id into room_ from private.memberships where user_id=actor and state<>'ended';
 if room_ is null then return private.reply('getMyParticipation','unchanged','null'::jsonb,'{}'); end if;
 perform private.reconcile_room(room_);
 select jsonb_build_object('room_id',m.room_id,'membership_id',m.id,'generation',c.generation::text,
  'phase',case when c.detected_at is null and c.suspect_at>clock_timestamp() then 'active' else 'grace' end,'grace_deadline',c.grace_deadline) into data_
 from private.memberships m join private.connections c on c.membership_id=m.id where m.user_id=actor and m.room_id=room_ and m.state<>'ended';
 return private.reply('getMyParticipation','unchanged',data_,jsonb_build_object('room_revision',(select revision::text from private.rooms where id=room_)));

 exception when sqlstate 'P0001' then return private.failure('getMyParticipation',sqlerrm,req_);
 when invalid_text_representation or numeric_value_out_of_range then return private.failure('getMyParticipation','INVALID_INPUT',req_);
 end;
end $fn$;

create or replace function public.leave_room(room_id uuid, membership_id uuid, generation bigint, successor_membership_id uuid, expected_room_revision bigint, command_context_id uuid, request_id uuid) returns jsonb
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
  update private.rooms set revision=base_revision+1 where id=room_;
 end if;
 perform private.finish_room_command(actor,context_,req_,'leaveRoom',payload_,room_);
 return private.reply('leaveRoom','applied',jsonb_build_object('room_id',room_),jsonb_build_object('room_revision',(select revision::text from private.rooms where id=room_)),req_);

 exception when sqlstate 'P0001' then return private.failure('leaveRoom',sqlerrm,req_);
 when invalid_text_representation or numeric_value_out_of_range then return private.failure('leaveRoom','INVALID_INPUT',req_);
 end;
end $fn$;
reset role;
revoke create on schema public from assistae_room_api;
