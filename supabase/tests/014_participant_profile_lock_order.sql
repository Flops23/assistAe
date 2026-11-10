begin;
do $test$
declare a uuid:=gen_random_uuid(); b uuid:=gen_random_uuid(); n integer:=0; row_ record; denied boolean:=false;
begin
 insert into auth.users(id) values(a),(b);
 insert into private.profiles(user_id,public_code,nickname) values(a,'123412341234','Ana'),(b,'567856785678','Bia');
 perform set_config('request.jwt.claim.sub',a::text,true);
 set local role assistae_room_api;
 for row_ in select user_id from private.profiles where user_id in (a,b) order by user_id for update loop n:=n+1; end loop;
 assert n=2,'participant coordinator cannot lock both profiles before room';
 begin update private.profiles set revision=1 where user_id=b; exception when insufficient_privilege then denied:=true; end;
 assert denied,'coordinator lock grant allowed profile mutation';
 reset role;
 assert (select revision=0 from private.profiles where user_id=b),'profile changed through lock policy';
end
$test$;
rollback;
select 'participant_profile_lock_order: passed; fixtures rolled back' as result;
