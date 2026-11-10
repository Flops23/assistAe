begin;
do $test$
declare a uuid:=gen_random_uuid(); room_ uuid:=gen_random_uuid(); member_ uuid:=gen_random_uuid(); rejected boolean:=false;
begin
 insert into auth.users(id) values(a);
 insert into private.profiles(user_id,public_code,nickname) values(a,'DDDDDDDDDDDD','Ana');
 insert into private.rooms(id,name,admin_state) values(room_,'Sala','awaiting_successor');
 insert into private.memberships(id,room_id,user_id,join_order) values(member_,room_,a,1);
 begin
  insert into private.media_validations(actor_id,room_id,membership_id,source_url,source_digest,status,kind,duration_ms,duration_confidence,assessed_at)
   values(a,room_,member_,'https://example.com/video.mp4','fixture','valid','mp4',1000,'verified',clock_timestamp());
 exception when check_violation then rejected:=true;
 end;
 assert rejected, 'admitted validation without expiry accepted';
end
$test$;
rollback;
select 'media_validation_expiry: passed; fixtures rolled back' as result;
