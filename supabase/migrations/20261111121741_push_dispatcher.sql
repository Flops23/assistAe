create table private.push_installations (
 user_id uuid primary key references private.profiles(user_id) on delete cascade,
 fid text not null unique check(fid ~ '^[A-Za-z0-9_-]{22}$'),
 version uuid not null default gen_random_uuid(),
 refreshed_at timestamptz not null default clock_timestamp()
);
alter table private.push_installations enable row level security;
revoke all on private.push_installations from public,anon,authenticated,service_role;
alter table private.notification_outbox add column attempt_installation uuid;

create role assistae_push_api nologin noinherit nosuperuser nocreatedb nocreaterole noreplication nobypassrls;
create role assistae_push_worker nologin noinherit nosuperuser nocreatedb nocreaterole noreplication nobypassrls;
grant assistae_push_api,assistae_push_worker to postgres with inherit false,set true;
grant usage on schema public,private to assistae_push_api,assistae_push_worker;
grant execute on function private.session_actor(),private.require_actor(),private.consume_rate(uuid,text,numeric,numeric) to assistae_push_api;
grant select(user_id,enabled),update(enabled) on private.beta_testers to assistae_push_api;
create policy push_api_beta_read on private.beta_testers for select to assistae_push_api
 using(user_id=(select private.session_actor()));
create policy push_api_beta_lock on private.beta_testers for update to assistae_push_api
 using(user_id=(select private.session_actor())) with check(false);
grant select(user_id) on private.profiles to assistae_push_api;
create policy push_api_profile_read on private.profiles for select to assistae_push_api
 using(user_id=(select private.session_actor()));
grant select,insert,update on private.rate_buckets to assistae_push_api;
create policy push_api_rate on private.rate_buckets for all to assistae_push_api
 using(subject_key=(select private.session_actor())::text)
 with check(subject_key=(select private.session_actor())::text);
grant select,insert,delete,update(fid,version,refreshed_at) on private.push_installations to assistae_push_api;
create policy push_api_own_installation on private.push_installations for all to assistae_push_api
 using(user_id=(select private.session_actor())) with check(user_id=(select private.session_actor()));

grant select,delete on private.push_installations to assistae_push_worker;
create policy push_worker_installation_read on private.push_installations for select to assistae_push_worker using(true);
create policy push_worker_installation_delete on private.push_installations for delete to assistae_push_worker using(true);
grant select(user_id,enabled) on private.beta_testers to assistae_push_worker;
grant select(user_id,notify_invites,notify_friendships) on private.preferences to assistae_push_worker;
grant select(id,recipient_id,status) on private.friendship_requests to assistae_push_worker;
grant select(id,room_id,recipient_id,status) on private.room_invites to assistae_push_worker;
grant select(id,status) on private.rooms to assistae_push_worker;
grant select(room_id,user_id) on private.room_bans to assistae_push_worker;
grant select,update(status,attempts,next_attempt_at,lease_until,attempt_token,attempt_installation,delivered_at)
 on private.notification_outbox to assistae_push_worker;
create policy push_worker_beta_read on private.beta_testers for select to assistae_push_worker using(true);
create policy push_worker_preferences_read on private.preferences for select to assistae_push_worker using(true);
create policy push_worker_friendship_read on private.friendship_requests for select to assistae_push_worker using(true);
create policy push_worker_invite_read on private.room_invites for select to assistae_push_worker using(true);
create policy push_worker_room_read on private.rooms for select to assistae_push_worker using(true);
create policy push_worker_ban_read on private.room_bans for select to assistae_push_worker using(true);
create policy push_worker_outbox_read on private.notification_outbox for select to assistae_push_worker using(true);
create policy push_worker_outbox_update on private.notification_outbox for update to assistae_push_worker using(true) with check(true);

grant create on schema public to assistae_push_api;
set local role assistae_push_api;

create function public.register_push_installation(p_fid text) returns jsonb
language plpgsql security definer set search_path='' as $fn$
declare actor_ uuid;
begin
 begin
  actor_:=private.require_actor();
  perform private.consume_rate(actor_,'registerPushInstallation',6,60);
 exception when sqlstate 'P0001' then
  return jsonb_build_object('ok',false,'code',sqlerrm);
 end;

 if p_fid is null or p_fid !~ '^[A-Za-z0-9_-]{22}$' then
  return '{"ok":false,"code":"INVALID_INPUT"}';
 end if;
 if not exists(select 1 from private.profiles where user_id=actor_) then
  return '{"ok":false,"code":"NOT_FOUND_OR_UNAVAILABLE"}';
 end if;

 begin
  insert into private.push_installations as installation(user_id,fid) values(actor_,p_fid)
  on conflict(user_id) do update set fid=excluded.fid,refreshed_at=clock_timestamp(),
   version=case when installation.fid=excluded.fid then installation.version else excluded.version end;
 exception when unique_violation then
  return '{"ok":false,"code":"NOT_AVAILABLE"}';
 end;
 return '{"ok":true}';
end
$fn$;

create function public.unregister_push_installation(p_fid text) returns jsonb
language plpgsql security definer set search_path='' as $fn$
declare actor_ uuid:=private.session_actor();
begin
 if actor_ is null then return '{"ok":false,"code":"UNAUTHENTICATED"}'; end if;
 -- Revoked beta users can still detach a destination; they cannot register a new one.
 begin
  perform private.consume_rate(actor_,'unregisterPushInstallation',10,60);
 exception when sqlstate 'P0001' then
  return jsonb_build_object('ok',false,'code',sqlerrm);
 end;
 if p_fid is null or p_fid !~ '^[A-Za-z0-9_-]{22}$' then
  return '{"ok":false,"code":"INVALID_INPUT"}';
 end if;

 delete from private.push_installations where user_id=actor_ and fid=p_fid;
 return '{"ok":true}';
end
$fn$;

revoke all on function public.register_push_installation(text),public.unregister_push_installation(text)
 from public,anon,authenticated,service_role;
grant execute on function public.register_push_installation(text),public.unregister_push_installation(text) to authenticated;
reset role;
revoke create on schema public from assistae_push_api;

grant create on schema public to assistae_push_worker;
set local role assistae_push_worker;

create function public.worker_claim_push() returns jsonb
language plpgsql security definer set search_path='' as $fn$
declare job_ private.notification_outbox%rowtype; attempt_ uuid; at_ timestamptz:=clock_timestamp();
begin
 for job_ in
  select * from private.notification_outbox
  where (status='pending' and next_attempt_at<=at_) or (status='leased' and lease_until<=at_)
  order by case when status='pending' then next_attempt_at else lease_until end,id
  limit 20 for update skip locked
 loop
  if job_.created_at<=at_-interval '24 hours' or job_.attempts>=4 then
   update private.notification_outbox set status=case when job_.attempts>=4 then 'failed' else 'suppressed' end,
    lease_until=null,attempt_token=null,attempt_installation=null where id=job_.id;
   continue;
  end if;

  attempt_:=gen_random_uuid();
  update private.notification_outbox set status='leased',attempts=attempts+1,
   lease_until=clock_timestamp()+interval '45 seconds',attempt_token=attempt_,attempt_installation=null
  where id=job_.id;
  return jsonb_build_object('id',job_.id,'attempt',attempt_);
 end loop;
 return null;
end
$fn$;

create function public.worker_prepare_push(p_id uuid,p_attempt uuid) returns jsonb
language plpgsql security definer set search_path='' as $fn$
declare job_ private.notification_outbox%rowtype; fid_ text; version_ uuid;
begin
 select * into job_ from private.notification_outbox where id=p_id for update;
 if not found or job_.status<>'leased' or p_attempt is null or job_.attempt_token<>p_attempt
  or job_.lease_until<=clock_timestamp() or job_.attempt_installation is not null then return null; end if;

 select installation.fid,installation.version into fid_,version_
 from private.push_installations installation
 join private.beta_testers beta using(user_id)
 join private.preferences preference using(user_id)
 where installation.user_id=job_.recipient_id and beta.enabled
  and installation.refreshed_at>clock_timestamp()-interval '30 days'
  and job_.created_at>clock_timestamp()-interval '24 hours'
  and (
   (job_.kind='friendship' and preference.notify_friendships and exists (
    select 1 from private.friendship_requests request
    where request.id=job_.resource_id and request.recipient_id=job_.recipient_id and request.status='pending'
   )) or
   (job_.kind='invite' and preference.notify_invites and exists (
    select 1 from private.room_invites invite join private.rooms room on room.id=invite.room_id
    where invite.id=job_.resource_id and invite.recipient_id=job_.recipient_id
     and invite.status='pending' and room.status='active'
     and not exists(select 1 from private.room_bans ban where ban.room_id=room.id and ban.user_id=job_.recipient_id)
   ))
  );

 if not found then
  update private.notification_outbox set status='suppressed',lease_until=null,attempt_token=null
   where id=p_id;
  return null;
 end if;
 update private.notification_outbox set attempt_installation=version_ where id=p_id;
 return jsonb_build_object('fid',fid_,'kind',case when job_.kind='invite' then 'room_invite' else 'friend_request' end);
end
$fn$;

create function public.worker_finish_push(p_id uuid,p_attempt uuid,p_result text,p_retry_seconds integer)
returns boolean language plpgsql security definer set search_path='' as $fn$
declare job_ private.notification_outbox%rowtype; at_ timestamptz; next_ timestamptz; status_ text; removed_ boolean;
begin
 if p_result is null or p_result not in ('delivered','retry','failed','unregistered') then return false; end if;
 select * into job_ from private.notification_outbox where id=p_id for update;
 at_:=clock_timestamp();
 if not found or job_.status<>'leased' or p_attempt is null or job_.attempt_token<>p_attempt
  or job_.lease_until<=at_ or job_.attempt_installation is null then return false; end if;

 status_:=p_result;
 if p_result='unregistered' then
  delete from private.push_installations where user_id=job_.recipient_id and version=job_.attempt_installation;
  removed_:=found;
  status_:=case when not removed_ and exists(select 1 from private.push_installations where user_id=job_.recipient_id)
   then 'retry' else 'failed' end;
 end if;

 if status_='retry' then
  next_:=at_+make_interval(secs=>greatest(
   60 * (1 << (job_.attempts-1)) + floor(random()*15)::integer,
   least(coalesce(p_retry_seconds,0),86400)
  ));
  status_:=case when job_.attempts<4 and next_<job_.created_at+interval '24 hours' then 'pending' else 'failed' end;
 end if;

 update private.notification_outbox set status=status_,lease_until=null,attempt_token=null,attempt_installation=null,
  delivered_at=case when status_='delivered' then at_ end,next_attempt_at=coalesce(next_,next_attempt_at)
 where id=p_id;
 return true;
end
$fn$;

revoke all on function public.worker_claim_push(),public.worker_prepare_push(uuid,uuid),public.worker_finish_push(uuid,uuid,text,integer)
 from public,anon,authenticated,service_role;
grant execute on function public.worker_claim_push(),public.worker_prepare_push(uuid,uuid),public.worker_finish_push(uuid,uuid,text,integer)
 to service_role;
reset role;
revoke create on schema public from assistae_push_worker;
