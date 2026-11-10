begin;
do $test$
declare a uuid:=gen_random_uuid(); b uuid:=gen_random_uuid(); r jsonb; denied boolean:=false;
begin
 assert exists(select 1 from pg_roles where rolname='assistae_identity_api' and not rolcanlogin and not rolbypassrls and not rolsuper), 'limited API role missing';
 assert not exists(select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname in ('ensure_profile','get_my_profile','get_command_context','change_nickname','set_notification_preference','save_message_preferences')
  and pg_get_userbyid(p.proowner)<>'assistae_identity_api'), 'RPC still owned by privileged postgres';
 insert into auth.users(id) values(a),(b);
 insert into private.beta_testers(user_id) values(a),(b);
 perform set_config('request.jwt.claim.sub',a::text,true);
 set local role authenticated;
 r:=public.ensure_profile('Ana');
 assert r->'data'->>'nickname'='Ana','limited role bootstrap failed';
 assert not pg_has_role('authenticated','assistae_identity_api','MEMBER'),'authenticated is member of API role';
 reset role;
 insert into private.profiles(user_id,public_code,nickname) values(b,'ABABABABABAB','Bia');
 set local role assistae_identity_api;
 assert not exists(select 1 from private.profiles where user_id=b),'API role bypasses per-user RLS';
 denied:=false;
 begin update private.beta_testers set enabled=false where user_id=a; exception when insufficient_privilege then denied:=true; end;
 assert denied,'API role can change tester enrollment';
 denied:=false;
 begin insert into auth.users(id) values(gen_random_uuid()); exception when insufficient_privilege then denied:=true; end;
 assert denied,'API role can create auth users';
 assert not has_schema_privilege(current_user,'public','CREATE'),'API role retained schema CREATE';
 reset role;
end
$test$;
rollback;
select 'limited_identity_role: passed; fixtures rolled back' as result;
