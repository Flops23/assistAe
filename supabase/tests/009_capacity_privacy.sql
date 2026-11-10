begin;
do $test$
declare users_ uuid[]:='{}'; members_ uuid[]:='{}'; actor uuid; ctx uuid; r jsonb; room_ uuid; code_ text; invite_ uuid:=gen_random_uuid();
begin
 for i in 1..11 loop
  actor:=gen_random_uuid(); users_:=array_append(users_,actor);
  insert into auth.users(id) values(actor);
  insert into private.beta_testers(user_id) values(actor);
  perform set_config('request.jwt.claim.sub',actor::text,true);
  set local role authenticated;
  perform public.ensure_profile('Pessoa '||i);
  ctx:=(public.get_command_context()->'data'->>'command_context_id')::uuid;
  if i=1 then
   r:=public.create_room('Oculta',false,ctx,gen_random_uuid());
   room_:=(r->'data'->>'room_id')::uuid;
   members_:=array_append(members_,(r->'data'->>'membership_id')::uuid);
   code_:=public.get_room_code(room_,members_[1],1)->'data'->>'code';
  elsif i<=10 then
   r:=public.join_room(jsonb_build_object('code',code_),ctx,gen_random_uuid());
   assert r->>'code' is null,'authorized join rejected before capacity';
   members_:=array_append(members_,(r->'data'->>'membership_id')::uuid);
  end if;
  reset role;
 end loop;
 set local role authenticated;
 r:=public.join_room(jsonb_build_object('public_room_id',room_),ctx,gen_random_uuid());
 assert r->>'code'='NOT_FOUND_OR_UNAVAILABLE','private room admitted via public id';
 r:=public.join_room('[]'::jsonb,ctx,gen_random_uuid());
 assert r->>'code'='INVALID_INPUT','array target not rejected as input';
 r:=public.join_room(jsonb_build_object('code',code_),ctx,gen_random_uuid());
 assert r->>'code'='ROOM_FULL','eleventh person admitted';
 reset role;
 assert (select count(*)=10 from private.memberships where room_id=room_ and state<>'ended'),'capacity exceeded';
 update private.connections set last_seen_at=statement_timestamp()-interval '30 seconds',suspect_at=statement_timestamp()-interval '5 seconds',
  grace_deadline=statement_timestamp()+interval '55 seconds' where membership_id=members_[10];
 insert into private.room_invites(id,room_id,sender_id,recipient_id) values(invite_,room_,users_[1],users_[11]);
 set local role authenticated;
 r:=public.join_room(jsonb_build_object('invite_id',invite_),ctx,gen_random_uuid());
 assert r->>'code'='ROOM_FULL','reserved slot did not consume capacity';
 reset role;
 assert (select status='pending' from private.room_invites where id=invite_),'full room consumed invitation';
 update private.connections set last_seen_at=statement_timestamp()-interval '90 seconds',suspect_at=statement_timestamp()-interval '65 seconds',
  grace_deadline=statement_timestamp()-interval '5 seconds' where membership_id=members_[10];
 set local role authenticated;
 r:=public.join_room(jsonb_build_object('invite_id',invite_),ctx,gen_random_uuid());
 assert r->>'code' is null and r->'data'->>'room_id'=room_::text,'expired slot did not become available';
 members_:=array_append(members_,(r->'data'->>'membership_id')::uuid);
 r:=public.get_my_participation();
 assert r->'data'->>'membership_id'=members_[11]::text and r->'data'->>'room_id'=room_::text,'own participation reference';
 reset role;
 assert (select status='used' from private.room_invites where id=invite_),'successful admission did not consume invite';
 assert (select state='ended' from private.memberships where id=members_[10]),'expired membership revived';
 assert (select count(*)=10 from private.memberships where room_id=room_ and state<>'ended'),'wrong occupied count after expiry';
 -- Somente conectados no contador visível, enquanto grace ainda ocupa a vaga.
 update private.connections set last_seen_at=statement_timestamp()-interval '30 seconds',suspect_at=statement_timestamp()-interval '5 seconds',
  grace_deadline=statement_timestamp()+interval '55 seconds' where membership_id=members_[9];
 set local role authenticated;
 r:=public.get_room_snapshot(room_,members_[11],1);
 assert (r->'data'->>'connected_count')::integer=9,'reserved member included in visible count';
 reset role;
 insert into private.messages(room_id,seq,sender_membership_id,sender_id,client_message_id,sender_nickname,body)
  values(room_,1,members_[1],users_[1],gen_random_uuid(),'Pessoa 1','Fixture');
 update private.room_counters set last_message_seq=1 where room_id=room_;
 perform set_config('request.jwt.claim.sub',users_[1]::text,true);
 set local role authenticated;
 ctx:=(public.get_command_context()->'data'->>'command_context_id')::uuid;
 r:=public.get_room_snapshot(room_,members_[1],1);
 r:=public.close_room(room_,members_[1],1,(r->'revisions'->>'room_revision')::bigint,ctx,gen_random_uuid());
 assert r->>'code' is null,'admin failed to close';
 reset role;
 assert not exists(select 1 from private.messages where room_id=room_),'closure retained chat messages';
 assert not exists(select 1 from private.memberships where room_id=room_ and state<>'ended'),'closure retained occupied slots';
end
$test$;
rollback;
select 'capacity_privacy_invites: passed; fixtures rolled back; parallel contention not covered' as result;
