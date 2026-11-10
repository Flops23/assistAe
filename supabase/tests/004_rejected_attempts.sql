begin;
do $test$
declare actor uuid:=gen_random_uuid(); context_ uuid:=gen_random_uuid(); result_ jsonb;
begin
 insert into auth.users(id) values(actor);
 insert into private.beta_testers(user_id) values(actor);
 insert into private.profiles(user_id,public_code,nickname) values(actor,'EEEEEEEEEEEE','Ana');
 insert into private.preferences(user_id) values(actor);
 insert into private.command_contexts(id,actor_id,expires_at) values(context_,actor,clock_timestamp()+interval '1 hour');
 perform set_config('request.jwt.claim.sub',actor::text,true);
 set local role authenticated;
 for i in 1..31 loop
  begin result_:=public.change_nickname('Bia',999,context_,gen_random_uuid());
  exception when sqlstate 'P0001' then result_:=jsonb_build_object('code',sqlerrm);
  end;
 end loop;
 assert result_->>'code'='RATE_LIMITED', 'rejected attempts bypass rate limit';
 reset role;
 assert (select nickname='Ana' and revision=0 from private.profiles where user_id=actor), 'rejected attempt modified profile';
end
$test$;
rollback;
select 'rejected_attempt_rate: passed; fixtures rolled back' as result;
