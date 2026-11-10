alter policy room_profile_lock on private.profiles using(true) with check(false);
grant create on schema private to assistae_room_api;
set local role assistae_room_api;
create or replace function private.manage_participant(op text,p_room uuid,p_member uuid,p_generation bigint,p_target uuid,p_allowed boolean,p_revision bigint,p_context uuid,p_request uuid) returns jsonb
language plpgsql security invoker set search_path='' as $fn$
declare actor uuid; payload_ jsonb; replay_ jsonb; base_ bigint; target_ record; changed_ boolean:=true; data_ jsonb;
begin
 begin actor:=private.require_actor(); perform private.consume_rate(actor,op,30,60);
 exception when sqlstate 'P0001' then return private.failure(op,sqlerrm,p_request); end;
 begin
  payload_:=jsonb_build_object('room_id',p_room,'membership_id',p_member,'generation',p_generation::text,'target_membership_id',p_target,'allowed',p_allowed,'expected_room_revision',p_revision::text);
  replay_:=private.start_command(actor,p_context,p_request,op,payload_);
  if replay_ is not null then return replay_; end if;
  if op is null or op not in ('setControlPermission','transferAdmin','kickMember') or p_target is null or p_revision is null or p_revision<0
   or (op='setControlPermission' and p_allowed is null) then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
  perform 1 from private.profiles where user_id in (actor,(select user_id from private.memberships where id=p_target and room_id=p_room)) order by user_id for update;
  perform 1 from private.rooms where id=p_room for update;
  select revision into base_ from private.rooms where id=p_room;
  perform private.reconcile_room(p_room);
  perform private.require_live(actor,p_room,p_member,p_generation,'admin');
  if p_revision<>(select revision from private.rooms where id=p_room) then raise exception using message='CONFLICT',errcode='P0001'; end if;
  if p_target=p_member then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
  select m.state,m.user_id,m.can_control,c.detected_at,c.suspect_at into target_
   from private.memberships m join private.connections c on c.membership_id=m.id where m.id=p_target and m.room_id=p_room;
  if not found then raise exception using message='NOT_FOUND_OR_UNAVAILABLE',errcode='P0001'; end if;
  if target_.state='ended' then raise exception using message='CONFLICT',errcode='P0001'; end if;
  perform private.require_current_context(actor,p_context);
  if op='setControlPermission' then
   changed_:=target_.can_control is distinct from p_allowed;
   if changed_ then update private.memberships set can_control=p_allowed where id=p_target; end if;
   data_:=jsonb_build_object('membership_id',p_target,'can_control',p_allowed);
  elsif op='transferAdmin' then
   if target_.state<>'active' or target_.detected_at is not null or target_.suspect_at<=clock_timestamp() then raise exception using message='CONFLICT',errcode='P0001'; end if;
   update private.rooms set admin_state='assigned',admin_membership_id=p_target where id=p_room;
   data_:=jsonb_build_object('admin_membership_id',p_target);
  else
   update private.memberships set state='ended',ended_at=clock_timestamp(),end_reason='kicked' where id=p_target;
   update private.connections set generation=generation+1 where membership_id=p_target;
   update private.chat_windows w set end_at_seq=c.last_message_seq from private.room_counters c where w.membership_id=p_target and w.end_at_seq is null and c.room_id=p_room;
   insert into private.room_bans(room_id,user_id,actor_id) values(p_room,target_.user_id,actor) on conflict do nothing;
   data_:=jsonb_build_object('membership_id',p_target);
  end if;
  if changed_ then update private.rooms set revision=base_+1 where id=p_room; end if;
  perform private.finish_room_command(actor,p_context,p_request,op,payload_,p_room);
  return private.reply(op,case when changed_ then 'applied' else 'unchanged' end,data_,jsonb_build_object('room_revision',(select revision::text from private.rooms where id=p_room)),p_request);
 exception when sqlstate 'P0001' then return private.failure(op,sqlerrm,p_request); end;
end $fn$;
reset role;
revoke create on schema private from assistae_room_api;
