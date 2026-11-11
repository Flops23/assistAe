begin;
do $test$
declare
  admin_user uuid:=gen_random_uuid(); guest_user uuid:=gen_random_uuid(); outsider_user uuid:=gen_random_uuid();
  admin_topic text:='assistae:account:'||admin_user; guest_topic text:='assistae:account:'||guest_user;
  outsider_topic text:='assistae:account:'||outsider_user;
  room_ uuid; admin_member uuid; guest_member uuid; context_ uuid; admin_window uuid;
  guest_before integer; admin_before integer; outsider_before integer; response jsonb; denied boolean;
  validation_ uuid:=gen_random_uuid(); src text:='https://example.com/realtime.mp4'; at_ timestamptz;
begin
  assert exists(select 1 from pg_policies where schemaname='realtime' and tablename='messages'
    and policyname='assistae_read_account_refresh'), 'Realtime account policy missing';

  insert into auth.users(id) values(admin_user),(guest_user),(outsider_user);
  insert into private.beta_testers(user_id) values(admin_user),(guest_user),(outsider_user);
  perform set_config('request.jwt.claim.sub',admin_user::text,true);
  set local role authenticated;
  perform public.ensure_profile('Ana');
  context_:=(public.get_command_context()->'data'->>'command_context_id')::uuid;
  response:=public.create_room('Realtime',true,context_,gen_random_uuid());
  room_:=(response->'data'->>'room_id')::uuid;
  admin_member:=(response->'data'->>'membership_id')::uuid;
  admin_window:=(response->'data'->>'chat_window_id')::uuid;
  assert room_ is not null and admin_member is not null and admin_window is not null, 'room setup failed';

  perform set_config('request.jwt.claim.sub',guest_user::text,true);
  perform public.ensure_profile('Bia');
  response:=public.join_room(jsonb_build_object('public_room_id',room_),
    (public.get_command_context()->'data'->>'command_context_id')::uuid,gen_random_uuid());
  guest_member:=(response->'data'->>'membership_id')::uuid;
  assert guest_member is not null, 'join setup failed';

  set constraints all immediate;
  reset role;
  assert exists(select 1 from realtime.messages where topic=admin_topic), 'room did not notify its admin';
  assert exists(select 1 from realtime.messages where topic=guest_topic), 'room did not notify its guest';
  assert not exists(select 1 from realtime.messages where topic=outsider_topic), 'room activity leaked to an outsider';

  set local role authenticated;
  perform set_config('realtime.topic',guest_topic,true);
  assert exists(select 1 from realtime.messages where topic=guest_topic), 'own channel is not readable';
  perform set_config('realtime.topic',admin_topic,true);
  assert not exists(select 1 from realtime.messages where topic=admin_topic), 'other account is readable';
  denied:=false;
  begin
    insert into realtime.messages(topic,extension,payload,event,private)
    values(guest_topic,'broadcast','{}','refresh',true);
  exception when insufficient_privilege then denied:=true;
  end;
  assert denied, 'client can insert a refresh';
  reset role;

  select count(*) into guest_before from realtime.messages where topic=guest_topic;
  at_:=clock_timestamp();
  update private.connections set last_seen_at=at_-interval '30 seconds',suspect_at=at_-interval '5 seconds',
    grace_deadline=at_+interval '55 seconds' where membership_id=guest_member;
  perform set_config('request.jwt.claim.sub',admin_user::text,true);
  set local role authenticated;
  response:=public.heartbeat(room_,admin_member,1,1);
  assert response->>'outcome'='applied', 'heartbeat setup failed';
  reset role;
  assert (select count(*) from realtime.messages where topic=guest_topic)=guest_before+1,
    'guest in grace did not get exactly one own invalidation';
  select count(*) into guest_before from realtime.messages where topic=guest_topic;
  set local role authenticated;
  response:=public.send_message(room_,admin_member,1,admin_window,'During grace',gen_random_uuid(),context_,gen_random_uuid());
  assert response->>'outcome'='applied', 'chat during grace setup failed';
  reset role;
  assert (select count(*) from realtime.messages where topic=guest_topic)=guest_before,
    'guest in grace still receives room activity';

  set local role authenticated;
  response:=public.get_room_snapshot(room_,admin_member,1);
  response:=public.kick_member(room_,admin_member,1,guest_member,
    (response->'revisions'->>'room_revision')::bigint,context_,gen_random_uuid());
  assert response->>'outcome'='applied', 'kick setup failed';
  reset role;
  assert (select count(*) from realtime.messages where topic=guest_topic)=guest_before+1,
    'expelled user did not receive exactly one own invalidation';
  select count(*) into guest_before from realtime.messages where topic=guest_topic;
  select count(*) into admin_before from realtime.messages where topic=admin_topic;

  set local role authenticated;
  response:=public.send_message(room_,admin_member,1,admin_window,'Private content',gen_random_uuid(),context_,gen_random_uuid());
  assert response->>'outcome'='applied', 'chat setup failed';
  reset role;
  assert (select count(*) from realtime.messages where topic=guest_topic)=guest_before,
    'expelled user still receives room activity';
  assert (select count(*) from realtime.messages where topic=admin_topic)=admin_before+1,
    'chat mutation did not reach the live admin';

  insert into private.media_validations(id,actor_id,room_id,membership_id,source_url,source_digest,status,kind,
    duration_confidence,source_fingerprint,assessed_at,expires_at)
  values(validation_,admin_user,room_,admin_member,src,'fixture','inconclusive','mp4','inconclusive',repeat('a',64),
    clock_timestamp(),clock_timestamp()+interval '5 minutes');
  select count(*) into admin_before from realtime.messages where topic=admin_topic;
  set local role authenticated;
  response:=public.add_to_queue(room_,admin_member,1,src,validation_,0,context_,gen_random_uuid());
  assert response->>'outcome'='applied', 'queue setup failed';
  reset role;
  assert (select count(*) from realtime.messages where topic=admin_topic)=admin_before+1,
    'queue revision did not notify the live admin';
  set local role authenticated;
  response:=public.start_queue(room_,admin_member,1,0,1,context_,gen_random_uuid());
  assert response->>'outcome'='applied', 'playback setup failed';
  reset role;
  select count(*) into admin_before from realtime.messages where topic=admin_topic;
  set local role authenticated;
  response:=public.set_playback(room_,admin_member,1,'pause',null,1,1,context_,gen_random_uuid());
  assert response->>'outcome'='applied', 'pause setup failed';
  reset role;
  assert (select count(*) from realtime.messages where topic=admin_topic)=admin_before+1,
    'playback revision did not notify the live admin';
  assert (select count(*) from realtime.messages where topic=guest_topic)=guest_before,
    'expelled user still receives media activity';

  perform set_config('request.jwt.claim.sub',outsider_user::text,true);
  set local role authenticated;
  perform public.ensure_profile('Carol');
  response:=public.join_room(jsonb_build_object('public_room_id',room_),
    (public.get_command_context()->'data'->>'command_context_id')::uuid,gen_random_uuid());
  assert response->>'outcome'='applied', 'third actor join failed';
  reset role;
  select count(*) into outsider_before from realtime.messages where topic=outsider_topic;
  assert outsider_before>0, 'live third actor did not receive refresh';
  update private.beta_testers set enabled=false where user_id=outsider_user;
  perform set_config('request.jwt.claim.sub',admin_user::text,true);
  set local role authenticated;
  response:=public.send_message(room_,admin_member,1,admin_window,'After beta revocation',gen_random_uuid(),context_,gen_random_uuid());
  assert response->>'outcome'='applied', 'chat after beta revocation setup failed';
  reset role;
  assert (select count(*) from realtime.messages where topic=outsider_topic)=outsider_before,
    'disabled beta tester still receives refresh signals';
  assert not exists(select 1 from realtime.messages where topic in (admin_topic,guest_topic)
    and (event is distinct from 'refresh' or extension is distinct from 'broadcast'
      or private is distinct from true or payload is distinct from '{}'::jsonb)), 'refresh carries unexpected data';
end $test$;
rollback;
select 'realtime_refresh: passed; fixtures rolled back' as result;
