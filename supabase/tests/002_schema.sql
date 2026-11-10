begin;
do $test$
declare a uuid:=gen_random_uuid(); b uuid:=gen_random_uuid(); r1 uuid:=gen_random_uuid(); r2 uuid:=gen_random_uuid(); m1 uuid:=gen_random_uuid(); rejected boolean;
begin
  assert to_regclass('private.profiles') is not null, 'domain schema missing';
  assert not exists(select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='private' and c.relkind='r' and not c.relrowsecurity), 'RLS disabled';
  assert not has_schema_privilege('authenticated','private','USAGE'), 'private exposed';
  insert into auth.users(id) values(a),(b);
  insert into private.profiles(user_id,public_code,nickname) values(a,'AAAAAAAAAAAA','Ana'),(b,'BBBBBBBBBBBB','Bia');
  insert into private.rooms(id,name,admin_state) values(r1,'Sala A','awaiting_successor'),(r2,'Sala B','awaiting_successor');
  insert into private.memberships(id,room_id,user_id,join_order) values(m1,r1,a,1);
  rejected:=false;
  begin insert into private.memberships(room_id,user_id,join_order) values(r2,a,1); exception when unique_violation then rejected:=true; end;
  assert rejected, 'one person admitted to two rooms';
  rejected:=false;
  begin update private.rooms set admin_state='assigned',admin_membership_id=m1 where id=r2; set constraints all immediate; exception when foreign_key_violation then rejected:=true; end;
  assert rejected, 'admin from another room accepted';
  set constraints all deferred;
  rejected:=false;
  begin insert into private.playback(room_id,status,position_ms) values(r1,'playing',0); exception when check_violation then rejected:=true; end;
  assert rejected, 'playing without media accepted';
  rejected:=false;
  begin insert into private.profiles(user_id,public_code,nickname) values(gen_random_uuid(),'CCCCCCCCCCCC','X'); exception when check_violation then rejected:=true; end;
  assert rejected, 'nickname minimum not enforced';
  rejected:=false;
  begin insert into private.messages(room_id,seq,sender_membership_id,sender_id,client_message_id,sender_nickname,body)
    values(r2,1,m1,a,gen_random_uuid(),'Ana','Oi'); exception when foreign_key_violation then rejected:=true; end;
  assert rejected, 'cross room message accepted';
  rejected:=false;
  begin insert into private.notification_outbox(recipient_id,event_key,resource_id,kind,status)
    values(a,'test',gen_random_uuid(),'invite','leased'); exception when check_violation then rejected:=true; end;
  assert rejected, 'lease without token accepted';
end
$test$;
rollback;
select 'schema_integrity: passed; fixtures rolled back' as result;
