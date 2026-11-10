create role assistae_social_api nologin noinherit nosuperuser nocreatedb nocreaterole noreplication nobypassrls;
grant assistae_social_api to postgres with inherit false,set true;
grant usage on schema public,private to assistae_social_api;
grant execute on function private.session_actor(),private.require_actor(),private.consume_rate(uuid,text,numeric,numeric),
 private.reply(text,text,jsonb,jsonb,uuid),private.failure(text,text,uuid),private.start_command(uuid,uuid,uuid,text,jsonb),
 private.require_current_context(uuid,uuid),private.require_live(uuid,uuid,uuid,bigint,text) to assistae_social_api;
grant select(user_id,public_code,nickname) on private.profiles to assistae_social_api;
grant update(revision) on private.profiles to assistae_social_api;
create policy social_profile_read on private.profiles for select to assistae_social_api using(true);
create policy social_profile_lock on private.profiles for update to assistae_social_api using(true) with check(false);
grant select(user_id,notify_invites,notify_friendships) on private.preferences to assistae_social_api;
create policy social_notification_preference on private.preferences for select to assistae_social_api using(true);
grant select on private.beta_testers,private.command_contexts,private.command_receipts,private.rate_buckets to assistae_social_api;
grant update(enabled) on private.beta_testers to assistae_social_api;
grant update(expires_at) on private.command_contexts to assistae_social_api;
grant insert on private.command_receipts,private.rate_buckets to assistae_social_api;
grant update on private.rate_buckets to assistae_social_api;
create policy social_beta_read on private.beta_testers for select to assistae_social_api using(user_id=(select private.session_actor()));
create policy social_beta_lock on private.beta_testers for update to assistae_social_api using(user_id=(select private.session_actor())) with check(false);
create policy social_context_read on private.command_contexts for select to assistae_social_api using(actor_id=(select private.session_actor()));
create policy social_context_lock on private.command_contexts for update to assistae_social_api using(actor_id=(select private.session_actor())) with check(false);
create policy social_receipt_read on private.command_receipts for select to assistae_social_api using(actor_id=(select private.session_actor()));
create policy social_receipt_insert on private.command_receipts for insert to assistae_social_api with check(actor_id=(select private.session_actor()));
create policy social_bucket on private.rate_buckets for all to assistae_social_api using(subject_key=(select private.session_actor())::text) with check(subject_key=(select private.session_actor())::text);
grant select,insert on private.friendship_pairs,private.friendship_requests to assistae_social_api;
grant update(user_low) on private.friendship_pairs to assistae_social_api;
grant update(status,resolved_at) on private.friendship_requests to assistae_social_api;
grant select,insert,delete on private.friendships to assistae_social_api;
create policy social_pair_read on private.friendship_pairs for select to assistae_social_api using((select private.session_actor()) in (user_low,user_high));
create policy social_pair_insert on private.friendship_pairs for insert to assistae_social_api with check((select private.session_actor()) in (user_low,user_high));
create policy social_pair_lock on private.friendship_pairs for update to assistae_social_api using((select private.session_actor()) in (user_low,user_high)) with check(false);
create policy social_request_read on private.friendship_requests for select to assistae_social_api using((select private.session_actor()) in (sender_id,recipient_id));
create policy social_request_insert on private.friendship_requests for insert to assistae_social_api with check(sender_id=(select private.session_actor()));
create policy social_request_update on private.friendship_requests for update to assistae_social_api using((select private.session_actor()) in (sender_id,recipient_id)) with check((select private.session_actor()) in (sender_id,recipient_id));
create policy social_friendships on private.friendships for all to assistae_social_api using((select private.session_actor()) in (user_low,user_high)) with check((select private.session_actor()) in (user_low,user_high));
grant select,insert on private.room_invites to assistae_social_api;
create policy social_invite_read on private.room_invites for select to assistae_social_api using(true);
create policy social_invite_insert on private.room_invites for insert to assistae_social_api with check(sender_id=(select private.session_actor()));
grant select on private.rooms,private.memberships,private.connections,private.room_bans to assistae_social_api;
grant update(revision) on private.rooms to assistae_social_api;
create policy social_room_read on private.rooms for select to assistae_social_api using(true);
create policy social_room_lock on private.rooms for update to assistae_social_api using(true) with check(false);
create policy social_membership_read on private.memberships for select to assistae_social_api using(true);
create policy social_connection_read on private.connections for select to assistae_social_api using(true);
create policy social_ban_read on private.room_bans for select to assistae_social_api using(true);
grant select,insert on private.notification_outbox to assistae_social_api;
grant update(status,lease_until,attempt_token) on private.notification_outbox to assistae_social_api;
create policy social_outbox on private.notification_outbox for all to assistae_social_api using(true) with check(true);
grant create on schema public,private to assistae_social_api;
set local role assistae_social_api;

create function private.finish_social_command(actor uuid,context_ uuid,request_ uuid,op text,payload_ jsonb,resource_ uuid,result_ text) returns void
language sql volatile security invoker set search_path='' as $$
 insert into private.command_receipts(actor_id,request_id,command_context_id,operation,payload_hash,resource_id,result_code,expires_at)
 select actor,request_,context_,op,encode(sha256(convert_to(jsonb_build_object('contract_version','1','context',context_,'operation',op,'payload',payload_)::text,'UTF8')),'hex'),
 resource_,result_,expires_at+interval '24 hours' from private.command_contexts where id=context_ and actor_id=actor
$$;
revoke all on function private.finish_social_command(uuid,uuid,uuid,text,jsonb,uuid,text) from public,anon,authenticated,service_role;

create function private.social_command(op text,p_other uuid,p_code text,p_resource uuid,p_answer text,p_room uuid,p_member uuid,p_generation bigint,p_context uuid,p_request uuid) returns jsonb
language plpgsql security invoker set search_path='' as $fn$
declare actor uuid; other_ uuid; low_ uuid; high_ uuid; result_id uuid; status_ text; data_ jsonb; payload_ jsonb; replay_ jsonb;
 request_ private.friendship_requests%rowtype; changed_ boolean:=false; affected integer;
begin
 begin actor:=private.require_actor(); perform private.consume_rate(actor,op,case when op='requestFriendship' then 10 else 30 end,60);
 exception when sqlstate 'P0001' then return private.failure(op,sqlerrm,p_request); end;
 begin
  payload_:=jsonb_build_object('other',p_other,'code',p_code,'resource',p_resource,'answer',p_answer,'room',p_room,'membership',p_member,'generation',p_generation::text);
  replay_:=private.start_command(actor,p_context,p_request,op,payload_);
  if replay_ is not null then return replay_; end if;
  if op is null or op not in ('requestFriendship','answerFriendRequest','cancelFriendRequest','removeFriend','inviteFriend') then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
  if op='requestFriendship' then
   if p_code is null or upper(btrim(p_code))!~'^[A-F0-9]{12}$' then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
   select user_id into other_ from private.profiles where public_code=upper(btrim(p_code));
  elsif op in ('answerFriendRequest','cancelFriendRequest') then
   if op='answerFriendRequest' and (p_answer is null or p_answer not in ('accept','reject')) then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
   select * into request_ from private.friendship_requests f where f.id=p_resource and
    ((op='answerFriendRequest' and f.recipient_id=actor) or (op='cancelFriendRequest' and f.sender_id=actor));
   if not found then raise exception using message='NOT_FOUND_OR_UNAVAILABLE',errcode='P0001'; end if;
   other_:=case when request_.sender_id=actor then request_.recipient_id else request_.sender_id end;
  else other_:=p_other;
  end if;
  if other_ is null then raise exception using message='NOT_FOUND_OR_UNAVAILABLE',errcode='P0001'; end if;
  if other_=actor then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
  perform 1 from private.profiles where user_id in (actor,other_) order by user_id for update;
  low_:=least(actor,other_); high_:=greatest(actor,other_);
  if op='requestFriendship' then
   insert into private.friendship_pairs(user_low,user_high) values(low_,high_) on conflict do nothing;
  end if;
  perform 1 from private.friendship_pairs where user_low=low_ and user_high=high_ for update;
  perform private.require_current_context(actor,p_context);
  if op='requestFriendship' then
   if exists(select 1 from private.friendships where user_low=low_ and user_high=high_) then
    status_:='friends'; result_id:=other_; data_:=jsonb_build_object('status',status_,'friend_user_id',other_);
   else
    select * into request_ from private.friendship_requests where user_low=low_ and user_high=high_ and status='pending';
    if found then
     result_id:=request_.id; status_:=case when request_.sender_id=actor then 'pending' else 'received_request' end;
    else
     result_id:=gen_random_uuid(); status_:='pending'; changed_:=true;
     insert into private.friendship_requests(id,sender_id,recipient_id,user_low,user_high) values(result_id,actor,other_,low_,high_);
     insert into private.notification_outbox(recipient_id,event_key,resource_id,kind,status)
      values(other_,'friendship:'||result_id::text,result_id,'friendship',
       case when coalesce((select notify_friendships from private.preferences where user_id=other_),false) then 'pending' else 'suppressed' end);
    end if;
    data_:=jsonb_build_object('status',status_,'friend_request_id',result_id);
   end if;
  elsif op in ('answerFriendRequest','cancelFriendRequest') then
   select * into request_ from private.friendship_requests where id=p_resource;
   if not found or request_.status<>'pending' then raise exception using message='CONFLICT',errcode='P0001'; end if;
   status_:=case when op='cancelFriendRequest' then 'cancelled' when p_answer='accept' then 'accepted' else 'rejected' end;
   update private.friendship_requests set status=status_,resolved_at=clock_timestamp() where id=p_resource;
   if status_='accepted' then insert into private.friendships(user_low,user_high) values(low_,high_) on conflict do nothing; end if;
   update private.notification_outbox set status='suppressed',lease_until=null,attempt_token=null where resource_id=p_resource and kind='friendship' and status in ('pending','leased');
   changed_:=true; result_id:=p_resource; data_:=jsonb_build_object('status',status_,'friend_request_id',result_id,'friend_user_id',other_);
  elsif op='removeFriend' then
   delete from private.friendships where user_low=low_ and user_high=high_;
   get diagnostics affected=row_count; changed_:=affected>0;
   status_:=case when changed_ then 'removed' else 'already_absent' end; result_id:=other_;
   data_:=jsonb_build_object('status',status_,'friend_user_id',other_);
  else
   if not exists(select 1 from private.friendships where user_low=low_ and user_high=high_) then raise exception using message='FORBIDDEN',errcode='P0001'; end if;
   perform 1 from private.rooms where id=p_room for update;
   perform private.require_live(actor,p_room,p_member,p_generation);
   if exists(select 1 from private.room_bans where room_id=p_room and user_id=other_) then raise exception using message='FORBIDDEN',errcode='P0001'; end if;
   perform private.require_current_context(actor,p_context);
   select id into result_id from private.room_invites where room_id=p_room and recipient_id=other_ and status='pending';
   if not found then
    result_id:=gen_random_uuid(); changed_:=true;
    insert into private.room_invites(id,room_id,sender_id,recipient_id) values(result_id,p_room,actor,other_);
    insert into private.notification_outbox(recipient_id,event_key,resource_id,kind,status)
     values(other_,'invite:'||result_id::text,result_id,'invite',
      case when coalesce((select notify_invites from private.preferences where user_id=other_),false) then 'pending' else 'suppressed' end);
   end if;
   status_:='pending'; data_:=jsonb_build_object('status',status_,'invite_id',result_id);
  end if;
  perform private.finish_social_command(actor,p_context,p_request,op,payload_,result_id,status_);
  return private.reply(op,case when changed_ then 'applied' else 'unchanged' end,data_,'{}',p_request);
 exception when sqlstate 'P0001' then return private.failure(op,sqlerrm,p_request); end;
end $fn$;
revoke all on function private.social_command(text,uuid,text,uuid,text,uuid,uuid,bigint,uuid,uuid) from public,anon,authenticated,service_role;

create function public.request_friendship(user_code text,command_context_id uuid,request_id uuid) returns jsonb
language sql volatile security definer set search_path='' as $$ select private.social_command('requestFriendship',null,user_code,null,null,null,null,null,command_context_id,request_id) $$;
revoke all on function public.request_friendship(text,uuid,uuid) from public,anon,service_role;
grant execute on function public.request_friendship(text,uuid,uuid) to authenticated;
create function public.answer_friend_request(friend_request_id uuid,answer text,command_context_id uuid,request_id uuid) returns jsonb
language sql volatile security definer set search_path='' as $$ select private.social_command('answerFriendRequest',null,null,friend_request_id,answer,null,null,null,command_context_id,request_id) $$;
revoke all on function public.answer_friend_request(uuid,text,uuid,uuid) from public,anon,service_role;
grant execute on function public.answer_friend_request(uuid,text,uuid,uuid) to authenticated;
create function public.cancel_friend_request(friend_request_id uuid,command_context_id uuid,request_id uuid) returns jsonb
language sql volatile security definer set search_path='' as $$ select private.social_command('cancelFriendRequest',null,null,friend_request_id,null,null,null,null,command_context_id,request_id) $$;
revoke all on function public.cancel_friend_request(uuid,uuid,uuid) from public,anon,service_role;
grant execute on function public.cancel_friend_request(uuid,uuid,uuid) to authenticated;
create function public.remove_friend(friend_user_id uuid,command_context_id uuid,request_id uuid) returns jsonb
language sql volatile security definer set search_path='' as $$ select private.social_command('removeFriend',friend_user_id,null,null,null,null,null,null,command_context_id,request_id) $$;
revoke all on function public.remove_friend(uuid,uuid,uuid) from public,anon,service_role;
grant execute on function public.remove_friend(uuid,uuid,uuid) to authenticated;
create function public.invite_friend(friend_user_id uuid,room_id uuid,membership_id uuid,generation bigint,command_context_id uuid,request_id uuid) returns jsonb
language sql volatile security definer set search_path='' as $$ select private.social_command('inviteFriend',friend_user_id,null,null,null,room_id,membership_id,generation,command_context_id,request_id) $$;
revoke all on function public.invite_friend(uuid,uuid,uuid,bigint,uuid,uuid) from public,anon,service_role;
grant execute on function public.invite_friend(uuid,uuid,uuid,bigint,uuid,uuid) to authenticated;

create function public.list_friends(cursor uuid default null,limit_ integer default 20) returns jsonb
language plpgsql security definer set search_path='' as $fn$
declare actor uuid; data_ jsonb;
begin
 begin actor:=private.require_actor(); perform private.consume_rate(actor,'listFriends',60,60);
 exception when sqlstate 'P0001' then return private.failure('listFriends',sqlerrm); end;
 begin
  if limit_ is null or limit_ not between 1 and 50 then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
  with pair as (
   select case when f.user_low=actor then f.user_high else f.user_low end as other_
    from private.friendships f where actor in(f.user_low,f.user_high)
  ),page as (
   select other_,p.nickname from pair join private.profiles p on p.user_id=other_
    where cursor is null or other_>cursor order by other_ limit limit_+1
  ),visible as (select * from page order by other_ limit limit_)
  select jsonb_build_object('friends',(select coalesce(jsonb_agg(jsonb_build_object('user_id',other_,'nickname',nickname) order by other_),'[]') from visible),
  'next_cursor',case when (select count(*) from page)>limit_ then (select other_ from visible order by other_ desc limit 1) else null end) into data_;
  return private.reply('listFriends','unchanged',data_,'{}');
 exception when sqlstate 'P0001' then return private.failure('listFriends',sqlerrm); end;
end $fn$;
revoke all on function public.list_friends(uuid,integer) from public,anon,service_role;
grant execute on function public.list_friends(uuid,integer) to authenticated;
create function public.list_friend_requests(direction text,cursor jsonb default null,limit_ integer default 20) returns jsonb
language plpgsql security definer set search_path='' as $fn$
declare actor uuid; data_ jsonb; created_ timestamptz; id_ uuid; at_ timestamptz;
begin
 begin actor:=private.require_actor(); perform private.consume_rate(actor,'listFriendRequests',60,60);
 exception when sqlstate 'P0001' then return private.failure('listFriendRequests',sqlerrm); end;
 begin
  if limit_ is null or limit_ not between 1 and 50 then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
  if direction is null or direction not in ('incoming','outgoing') then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
  if cursor is not null then
   if jsonb_typeof(cursor)<>'object' then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
   if (select count(*) from jsonb_object_keys(cursor))<>2 or not(cursor ?& array['created_at','id']) then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
   created_:=(cursor->>'created_at')::timestamptz; id_:=(cursor->>'id')::uuid;
   if created_ is null or id_ is null then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
  end if;
  at_:=clock_timestamp();
  with page as (
 select f.id,f.status,f.created_at,f.resolved_at,case when f.sender_id=actor then f.recipient_id else f.sender_id end as other_user_id,p.nickname
 from private.friendship_requests f join private.profiles p on p.user_id=case when f.sender_id=actor then f.recipient_id else f.sender_id end
 where ((direction='incoming' and f.recipient_id=actor) or (direction='outgoing' and f.sender_id=actor))
 and (cursor is null or (f.created_at,f.id)<(created_,id_)) order by f.created_at desc,f.id desc limit limit_+1),visible as (select * from page order by created_at desc,id desc limit limit_)
  select jsonb_build_object('requests',(select coalesce(jsonb_agg(to_jsonb(visible) order by created_at desc,id desc),'[]') from visible),
   'next_cursor',case when (select count(*) from page)>limit_ then (select jsonb_build_object('created_at',created_at,'id',id) from visible order by created_at,id limit 1) else null end) into data_;
  return private.reply('listFriendRequests','unchanged',data_,'{}');
 exception when sqlstate 'P0001' then return private.failure('listFriendRequests',sqlerrm);
 when invalid_text_representation or invalid_datetime_format or datetime_field_overflow then return private.failure('listFriendRequests','INVALID_INPUT');
 end;
end $fn$;
revoke all on function public.list_friend_requests(text,jsonb,integer) from public,anon,service_role;
grant execute on function public.list_friend_requests(text,jsonb,integer) to authenticated;
create function public.list_invites(cursor jsonb default null,limit_ integer default 20) returns jsonb
language plpgsql security definer set search_path='' as $fn$
declare actor uuid; data_ jsonb; created_ timestamptz; id_ uuid; at_ timestamptz;
begin
 begin actor:=private.require_actor(); perform private.consume_rate(actor,'listInvites',60,60);
 exception when sqlstate 'P0001' then return private.failure('listInvites',sqlerrm); end;
 begin
  if limit_ is null or limit_ not between 1 and 50 then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;

  if cursor is not null then
   if jsonb_typeof(cursor)<>'object' then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
   if (select count(*) from jsonb_object_keys(cursor))<>2 or not(cursor ?& array['created_at','id']) then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
   created_:=(cursor->>'created_at')::timestamptz; id_:=(cursor->>'id')::uuid;
   if created_ is null or id_ is null then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
  end if;
  at_:=clock_timestamp();
  with page as (
 select i.id,i.room_id,r.name as room_name,i.sender_id,p.nickname as sender_nickname,i.created_at
 from private.room_invites i join private.rooms r on r.id=i.room_id join private.profiles p on p.user_id=i.sender_id
 where i.recipient_id=actor and i.status='pending' and r.status='active' and exists(select 1 from private.memberships m join private.connections c on c.membership_id=m.id
  where m.room_id=r.id and m.state<>'ended' and c.grace_deadline>at_)
 and (cursor is null or (i.created_at,i.id)<(created_,id_)) order by i.created_at desc,i.id desc limit limit_+1),visible as (select * from page order by created_at desc,id desc limit limit_)
  select jsonb_build_object('invites',(select coalesce(jsonb_agg(to_jsonb(visible) order by created_at desc,id desc),'[]') from visible),
   'next_cursor',case when (select count(*) from page)>limit_ then (select jsonb_build_object('created_at',created_at,'id',id) from visible order by created_at,id limit 1) else null end) into data_;
  return private.reply('listInvites','unchanged',data_,'{}');
 exception when sqlstate 'P0001' then return private.failure('listInvites',sqlerrm);
 when invalid_text_representation or invalid_datetime_format or datetime_field_overflow then return private.failure('listInvites','INVALID_INPUT');
 end;
end $fn$;
revoke all on function public.list_invites(jsonb,integer) from public,anon,service_role;
grant execute on function public.list_invites(jsonb,integer) to authenticated;
reset role;
revoke create on schema public,private from assistae_social_api;

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
  revision_key:=case when operation_='changeNickname' then 'profile_revision' when operation_ in ('setNotificationPreference','saveMessagePreferences') then 'preferences_revision' when operation_='sendMessage' then 'message_seq' else 'room_revision' end;
  return private.reply(operation_,'already_applied',
   jsonb_build_object('result_code',receipt.result_code,'resource_id',receipt.resource_id),
   case when receipt.result_revision is null then '{}'::jsonb else jsonb_build_object(revision_key,receipt.result_revision::text) end,request_);
 end if;
 select * into context_row from private.command_contexts where actor_id=actor and id=context_ for share;
 if not found or context_row.revoked_at is not null or context_row.contract_version<>'1' or clock_timestamp()>=context_row.expires_at then
  raise exception using message='REQUEST_EXPIRED',errcode='P0001';
 end if;
 return null;
end $$;
