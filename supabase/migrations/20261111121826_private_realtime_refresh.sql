-- Refresh signals carry no domain data. The client reads authorized state via RPC.
create role assistae_realtime_api nologin noinherit nosuperuser nocreatedb nocreaterole noreplication nobypassrls;
grant assistae_realtime_api to postgres with inherit false, set true;
grant usage on schema private, realtime to assistae_realtime_api;
grant select (user_id, enabled) on private.beta_testers to assistae_realtime_api;
grant select (id, status) on private.rooms to assistae_realtime_api;
grant select (id, room_id, user_id, state) on private.memberships to assistae_realtime_api;
grant select (membership_id, detected_at, suspect_at, grace_deadline) on private.connections to assistae_realtime_api;
grant insert (topic, extension, payload, event, private) on realtime.messages to assistae_realtime_api;

create policy assistae_realtime_enabled_beta on private.beta_testers for select to assistae_realtime_api using (enabled);
create policy assistae_realtime_rooms on private.rooms for select to assistae_realtime_api using (status = 'active');
create policy assistae_realtime_memberships on private.memberships for select to assistae_realtime_api using (state = 'active');
create policy assistae_realtime_connections on private.connections for select to assistae_realtime_api using (true);

create policy assistae_read_account_refresh on realtime.messages for select to authenticated
  using (extension = 'broadcast'
    and topic = (select realtime.topic())
    and topic = ('assistae:account:' || (select auth.uid())::text));
create policy assistae_no_client_account_refresh on realtime.messages as restrictive for insert to anon, authenticated
  with check (topic not like 'assistae:account:%');
create policy assistae_emit_account_refresh on realtime.messages for insert to assistae_realtime_api
  with check (extension = 'broadcast' and private is true and event = 'refresh' and payload = '{}'::jsonb
    and topic ~ '^assistae:account:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

grant create on schema private to assistae_realtime_api;
set local role assistae_realtime_api;
create function private.emit_realtime_refresh() returns trigger
language plpgsql security definer set search_path = '' as $refresh$
declare
  room_id_ uuid;
  affected_user uuid;
  now_ timestamptz := clock_timestamp();
begin
  if tg_table_name = 'memberships' then
    affected_user := new.user_id;
  elsif tg_table_name = 'rooms' then
    room_id_ := new.id;
  else
    room_id_ := new.room_id;
  end if;

  -- The platform's realtime.send adds a payload ID. Keep the app payload empty.
  insert into realtime.messages(topic, extension, payload, event, private)
  select 'assistae:account:' || audience.user_id::text, 'broadcast', '{}'::jsonb, 'refresh', true
  from (
    select affected_user as user_id where affected_user is not null
    union
    select member.user_id
    from private.rooms room
    join private.memberships member on member.room_id = room.id
    join private.connections connection on connection.membership_id = member.id
    where room.id = room_id_ and room.status = 'active' and member.state = 'active'
      and connection.detected_at is null and connection.suspect_at > now_ and connection.grace_deadline > now_
  ) audience
  join private.beta_testers tester on tester.user_id = audience.user_id and tester.enabled;
  return null;
exception when check_violation then
  -- Supabase creates the daily partition when a WebSocket connects. RPCs
  -- remain authoritative if there is no partition and no signal is queued.
  if sqlerrm like 'no partition of relation "messages" found for row%' then return null; end if;
  raise;
end $refresh$;
revoke all on function private.emit_realtime_refresh() from public, anon, authenticated, service_role;
grant execute on function private.emit_realtime_refresh() to postgres;
reset role;
revoke create on schema private from assistae_realtime_api;

-- Evaluate audience at transaction end, after membership and room changes.
create constraint trigger assistae_refresh_room_created after insert on private.rooms
  deferrable initially deferred for each row execute function private.emit_realtime_refresh();
create constraint trigger assistae_refresh_room_changed after update on private.rooms
  deferrable initially deferred for each row
  when (old.revision is distinct from new.revision or old.status is distinct from new.status)
  execute function private.emit_realtime_refresh();
create constraint trigger assistae_refresh_playback after update on private.playback
  deferrable initially deferred for each row when (old.revision is distinct from new.revision)
  execute function private.emit_realtime_refresh();
create constraint trigger assistae_refresh_queue after update on private.room_counters
  deferrable initially deferred for each row when (old.queue_revision is distinct from new.queue_revision)
  execute function private.emit_realtime_refresh();
create constraint trigger assistae_refresh_chat after insert on private.messages
  deferrable initially deferred for each row execute function private.emit_realtime_refresh();
create constraint trigger assistae_refresh_member_access after update on private.memberships
  deferrable initially deferred for each row when (old.state is distinct from new.state and new.state in ('grace', 'ended'))
  execute function private.emit_realtime_refresh();
