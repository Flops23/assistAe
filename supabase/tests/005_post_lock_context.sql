-- Revalidação de contexto após obter locks; sem alterar dados persistentes.
begin;
do $test$
declare actor uuid:=gen_random_uuid(); context_ uuid:=gen_random_uuid(); rejected boolean:=false; request_ uuid:=gen_random_uuid();
begin
 insert into auth.users(id) values(actor);
 insert into private.beta_testers(user_id) values(actor);
 insert into private.profiles(user_id,public_code,nickname) values(actor,'FFFFFFFFFFFF','Ana');
 insert into private.command_contexts(id,actor_id,expires_at) values(context_,actor,clock_timestamp()+interval '100 milliseconds');
 perform private.start_command(actor,context_,request_,'changeNickname','{}');
 perform 1 from private.profiles where user_id=actor for update;
 perform pg_sleep(0.15);
 begin perform private.require_current_context(actor,context_);
 exception when sqlstate 'P0001' then rejected:=sqlerrm='REQUEST_EXPIRED'; end;
 assert rejected, 'expired context survived post-lock time check';
 assert not exists(select 1 from private.command_receipts where actor_id=actor), 'expired request created receipt';
end
$test$;
rollback;
select 'post_lock_context: passed; fixtures rolled back; two-session contention not covered' as result;
