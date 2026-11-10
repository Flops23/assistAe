begin;
do $test$
declare a uuid:=gen_random_uuid(); b uuid:=gen_random_uuid(); ctx uuid; other_ctx uuid; req uuid:=gen_random_uuid(); r jsonb;
begin
 assert to_regprocedure('public.get_operation_status(uuid,uuid)') is not null,'operation status API missing';
 insert into auth.users(id) values(a),(b); insert into private.beta_testers(user_id) values(a),(b);
 perform set_config('request.jwt.claim.sub',a::text,true); set local role authenticated;
 perform public.ensure_profile('Ana'); ctx:=(public.get_command_context()->'data'->>'command_context_id')::uuid;
 r:=public.change_nickname('Ana Nova',0,ctx,req);
 r:=public.get_operation_status(req,ctx);
 assert r->'data'->>'status'='applied' and r->'data'->>'operation'='changeNickname','committed operation unknown';
 assert not(r->'data' ? 'nickname') and not(r->'data' ? 'body') and not(r->'data' ? 'public_code'),'operation status leaked result body';
 r:=public.get_operation_status(gen_random_uuid(),ctx); assert r->'data'->>'status'='unknown','valid unknown request status';
 perform set_config('request.jwt.claim.sub',b::text,true);
 perform public.ensure_profile('Bia'); other_ctx:=(public.get_command_context()->'data'->>'command_context_id')::uuid;
 r:=public.get_operation_status(req,ctx); assert r->'data'->>'status'='expired','another actor context was usable';
 reset role;
 update private.command_contexts set issued_at=clock_timestamp()-interval '1 hour',expires_at=clock_timestamp()-interval '1 second' where id=ctx;
 perform set_config('request.jwt.claim.sub',a::text,true); set local role authenticated;
 r:=public.get_operation_status(req,ctx); assert r->'data'->>'status'='applied','expired committed operation lost receipt';
 r:=public.get_operation_status(gen_random_uuid(),ctx); assert r->'data'->>'status'='expired','expired unknown request was retryable';
 reset role;
 assert (select nickname='Ana Nova' and revision=1 from private.profiles where user_id=a),'status query mutated domain';
end
$test$;
rollback;
select 'operation_status: passed; fixtures rolled back' as result;
