alter table private.media_validations add column generation bigint not null default 1 check(generation>=1),
 add column execution_token uuid,add column lease_until timestamptz,add column attempt_token uuid,
 add column attempts integer not null default 0 check(attempts between 0 and 3),add column failure_code text,
 add constraint validation_claim_pair check((lease_until is null)=(attempt_token is null)),
 add constraint validation_claim_pending check(lease_until is null or status='pending');
alter table private.queue_items add constraint queue_position_max check(position<=50);
create role assistae_media_worker nologin noinherit nosuperuser nocreatedb nocreaterole noreplication nobypassrls;
grant assistae_media_worker to postgres with inherit false,set true;
grant usage on schema public,private to assistae_media_worker;
grant select on private.media_validations,private.rooms,private.memberships,private.connections,private.beta_testers to assistae_media_worker;
grant update(status,kind,title,duration_ms,duration_confidence,source_fingerprint,assessed_at,expires_at,execution_token,lease_until,attempt_token,attempts,failure_code) on private.media_validations to assistae_media_worker;
grant update(revision) on private.rooms to assistae_media_worker;
grant update(enabled) on private.beta_testers to assistae_media_worker;
create policy worker_validation on private.media_validations for all to assistae_media_worker using(true) with check(true);
create policy worker_room_read on private.rooms for select to assistae_media_worker using(true);
create policy worker_room_lock on private.rooms for update to assistae_media_worker using(true) with check(false);
create policy worker_membership_read on private.memberships for select to assistae_media_worker using(true);
create policy worker_connection_read on private.connections for select to assistae_media_worker using(true);
create policy worker_beta_read on private.beta_testers for select to assistae_media_worker using(true);
create policy worker_beta_lock on private.beta_testers for update to assistae_media_worker using(true) with check(false);
grant execute on function private.require_live(uuid,uuid,uuid,bigint,text) to assistae_media_worker;
grant create on schema public,private to assistae_room_api;
set local role assistae_room_api;
create function private.finish_media_command(actor uuid,context_ uuid,request_ uuid,op text,payload_ jsonb,resource_ uuid,revision_ bigint default null) returns void
language sql volatile security invoker set search_path='' as $$
 insert into private.command_receipts(actor_id,request_id,command_context_id,operation,payload_hash,resource_id,result_code,result_revision,expires_at)
 select actor,request_,context_,op,encode(sha256(convert_to(jsonb_build_object('contract_version','1','context',context_,'operation',op,'payload',payload_)::text,'UTF8')),'hex'),
 resource_,'OK',revision_,expires_at+interval '24 hours' from private.command_contexts where id=context_ and actor_id=actor
$$;
revoke all on function private.finish_media_command(uuid,uuid,uuid,text,jsonb,uuid,bigint) from public,anon,authenticated,service_role;
create function public.validate_media(p_room uuid,p_member uuid,p_generation bigint,source_url text,command_context_id uuid,request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $fn$
declare actor uuid; payload_ jsonb; replay_ jsonb; id_ uuid:=gen_random_uuid(); nonce_ uuid:=gen_random_uuid(); at_ timestamptz;
begin
 begin actor:=private.require_actor();perform private.consume_rate(actor,'validateMedia',6,60);
 exception when sqlstate 'P0001' then return private.failure('validateMedia',sqlerrm,request_id);end;
 begin
  payload_:=jsonb_build_object('room_id',p_room,'membership_id',p_member,'generation',p_generation::text,'source_url',source_url);
  replay_:=private.start_command(actor,command_context_id,request_id,'validateMedia',payload_);
  if replay_ is not null then return replay_;end if;
  if source_url is null or octet_length(source_url)>8192 or source_url!~*'^https?://' or source_url~'[[:cntrl:]]' then raise exception using message='INVALID_INPUT',errcode='P0001';end if;
  perform 1 from private.profiles where user_id=actor for update;
  perform 1 from private.rooms where id=p_room for update;
  perform private.reconcile_room(p_room);perform private.require_live(actor,p_room,p_member,p_generation,'control');
  perform private.require_current_context(actor,command_context_id);at_:=clock_timestamp();
  insert into private.media_validations(id,actor_id,room_id,membership_id,generation,source_url,source_digest,execution_token,expires_at)
   values(id_,actor,p_room,p_member,p_generation,source_url,encode(sha256(convert_to(source_url,'UTF8')),'hex'),nonce_,at_+interval '10 minutes');
  perform private.finish_media_command(actor,command_context_id,request_id,'validateMedia',payload_,id_);
  return private.reply('validateMedia','applied',jsonb_build_object('validation_id',id_,'status','pending','execution_token',nonce_,'expires_at',at_+interval '10 minutes'),'{}',request_id);
 exception when sqlstate 'P0001' then return private.failure('validateMedia',sqlerrm,request_id);end;
end $fn$;
revoke all on function public.validate_media(uuid,uuid,bigint,text,uuid,uuid) from public,anon,service_role;
grant execute on function public.validate_media(uuid,uuid,bigint,text,uuid,uuid) to authenticated;
create function public.get_media_validation(p_room uuid,p_member uuid,p_generation bigint,validation_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $fn$
declare actor uuid; row_ private.media_validations%rowtype; status_ text;at_ timestamptz;
begin
 begin actor:=private.require_actor();perform private.consume_rate(actor,'getMediaValidation',120,60);
 exception when sqlstate 'P0001' then return private.failure('getMediaValidation',sqlerrm);end;
 begin
  perform 1 from private.rooms where id=p_room for update;
  perform private.reconcile_room(p_room);perform private.require_live(actor,p_room,p_member,p_generation);
  select * into row_ from private.media_validations v where v.id=validation_id and v.actor_id=actor and v.room_id=p_room and v.membership_id=p_member and v.generation=p_generation;
  if not found then raise exception using message='NOT_FOUND_OR_UNAVAILABLE',errcode='P0001';end if;
  at_:=clock_timestamp();
  status_:=case when row_.expires_at<=at_ or (row_.status='pending' and row_.attempts>=3 and coalesce(row_.lease_until,at_)<=at_) then 'expired' else row_.status end;
  return private.reply('getMediaValidation','unchanged',jsonb_build_object('validation_id',row_.id,'status',status_,'kind',row_.kind,'title',row_.title,
   'duration_ms',row_.duration_ms::text,'duration_confidence',row_.duration_confidence,'expires_at',row_.expires_at,'failure_code',row_.failure_code,
   'processing',row_.lease_until>at_,'execution_token',case when status_='pending' then row_.execution_token else null end,
   'validation_reference',case when status_ in ('valid','inconclusive') then row_.id else null end),'{}');
 exception when sqlstate 'P0001' then return private.failure('getMediaValidation',sqlerrm);end;
end $fn$;
revoke all on function public.get_media_validation(uuid,uuid,bigint,uuid) from public,anon,service_role;
grant execute on function public.get_media_validation(uuid,uuid,bigint,uuid) to authenticated;
reset role;
revoke create on schema public,private from assistae_room_api;
grant create on schema public to assistae_media_worker;
set local role assistae_media_worker;
create function public.worker_claim_media_validation(p_id uuid,p_token uuid) returns jsonb
language plpgsql security definer set search_path='' as $fn$
declare v private.media_validations%rowtype;attempt_ uuid:=gen_random_uuid();at_ timestamptz;
begin
 select * into v from private.media_validations where id=p_id;
 if not found or p_token is null or v.execution_token is distinct from p_token then return null;end if;
 perform 1 from private.beta_testers where user_id=v.actor_id and enabled for share;
 if not found then return null;end if;
 perform 1 from private.rooms where id=v.room_id for update;
 select * into v from private.media_validations where id=p_id for update;
 at_:=clock_timestamp();
 if not found or v.execution_token is distinct from p_token or v.status<>'pending' or v.expires_at<=at_ or v.attempts>=3 or v.lease_until>at_ then return null;end if;
 begin perform private.require_live(v.actor_id,v.room_id,v.membership_id,v.generation,'control');
 exception when sqlstate 'P0001' then
  update private.media_validations set status='expired',execution_token=null,lease_until=null,attempt_token=null,failure_code='STALE_CONTEXT' where id=p_id;return null;
 end;
 update private.media_validations set attempts=attempts+1,lease_until=at_+interval '30 seconds',attempt_token=attempt_ where id=p_id;
 return jsonb_build_object('validation_id',p_id,'source_url',v.source_url,'attempt_token',attempt_);
end $fn$;
revoke all on function public.worker_claim_media_validation(uuid,uuid) from public,anon,authenticated,service_role;
grant execute on function public.worker_claim_media_validation(uuid,uuid) to service_role;
create function public.worker_finish_media_validation(p_id uuid,p_attempt uuid,p_status text,p_kind text,p_duration bigint,p_fingerprint text,p_failure text) returns boolean
language plpgsql security definer set search_path='' as $fn$
declare v private.media_validations%rowtype;at_ timestamptz;
begin
 if p_status is null or p_status not in ('valid','inconclusive','invalid') or
  (p_status in ('valid','inconclusive') and (p_kind is null or p_kind not in ('mp4','hls') or p_fingerprint is null or p_fingerprint!~'^[a-f0-9]{64}$')) or
  (p_status='valid' and (p_duration is null or p_duration not between 1 and 9007199254740991)) or
  (p_status='inconclusive' and p_duration is not null) or
  (p_failure is not null and p_failure not in ('INVALID_URL','FORBIDDEN_DESTINATION','SOURCE_UNAVAILABLE','RESOURCE_LIMIT','TIME_LIMIT','UNSUPPORTED_FORMAT','LIVE_UNSUPPORTED','VOD_UNCONFIRMED','MALFORMED_MP4','MALFORMED_HLS','DRM_UNSUPPORTED','UNSUPPORTED_ENCODING','REDIRECT_LIMIT','PLAYLIST_CYCLE','VALIDATOR_ERROR')) then return false;end if;
 select * into v from private.media_validations where id=p_id;
 if not found then return false;end if;
 perform 1 from private.beta_testers where user_id=v.actor_id and enabled for share;
 if not found then return false;end if;
 perform 1 from private.rooms where id=v.room_id for update;
 select * into v from private.media_validations where id=p_id for update;
 at_:=clock_timestamp();
 if not found or v.status<>'pending' or p_attempt is null or v.attempt_token is distinct from p_attempt or v.lease_until<=at_ or v.expires_at<=at_ then return false;end if;
 begin perform private.require_live(v.actor_id,v.room_id,v.membership_id,v.generation,'control');
 exception when sqlstate 'P0001' then
  update private.media_validations set status='expired',execution_token=null,lease_until=null,attempt_token=null,failure_code='STALE_CONTEXT' where id=p_id;return false;
 end;
 update private.media_validations set status=p_status,kind=case when p_status='invalid' then null else p_kind end,title=null,
  duration_ms=case when p_status='valid' then p_duration else null end,
  duration_confidence=case when p_status='valid' then 'verified' when p_status='inconclusive' then 'inconclusive' else null end,
  source_fingerprint=case when p_status='invalid' then null else p_fingerprint end,assessed_at=at_,expires_at=at_+interval '5 minutes',
  execution_token=null,lease_until=null,attempt_token=null,failure_code=p_failure where id=p_id;
 return true;
end $fn$;
revoke all on function public.worker_finish_media_validation(uuid,uuid,text,text,bigint,text,text) from public,anon,authenticated,service_role;
grant execute on function public.worker_finish_media_validation(uuid,uuid,text,text,bigint,text,text) to service_role;
reset role;
revoke create on schema public from assistae_media_worker;
