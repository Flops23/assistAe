begin;
do $test$
declare actor uuid:=gen_random_uuid(); ctx uuid; room_ uuid; member_ uuid; r jsonb; ran integer;
begin
 insert into auth.users(id) values(actor);
 insert into private.beta_testers(user_id) values(actor);
 perform set_config('request.jwt.claim.sub',actor::text,true);
 set local role authenticated;
 perform public.ensure_profile('Ana');
 ctx:=(public.get_command_context()->'data'->>'command_context_id')::uuid;
 r:=public.create_room('Expirar',true,ctx,gen_random_uuid());
 room_:=(r->'data'->>'room_id')::uuid; member_:=(r->'data'->>'membership_id')::uuid;
 reset role;
 update private.connections set last_seen_at=statement_timestamp()-interval '90 seconds',
  suspect_at=statement_timestamp()-interval '65 seconds',grace_deadline=statement_timestamp()-interval '5 seconds' where membership_id=member_;
 ran:=private.expire_rooms(100);
 assert ran>=1,'deadline worker did not process expired room';
 assert (select status='closed' from private.rooms where id=room_),'worker did not close empty room';
 assert (select detected_at=suspect_at and detection_source='silence' from private.connections where membership_id=member_),'worker restarted detection';
 assert (select state='ended' and end_reason='lease_expired' from private.memberships where id=member_),'worker did not end expired membership';
 assert not has_function_privilege('authenticated','private.expire_rooms(integer)','EXECUTE'),'client can invoke worker';
 assert not has_function_privilege('anon','private.expire_rooms(integer)','EXECUTE'),'anon can invoke worker';
end
$test$;
rollback;
select 'deadline_worker: passed; fixtures rolled back' as result;
