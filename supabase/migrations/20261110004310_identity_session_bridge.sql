-- O schema auth é administrado pelo Supabase e postgres não dispõe de GRANT OPTION nele.
-- Ponte estreita: somente leitura da identidade já validada pelo PostgREST.
create function private.session_actor() returns uuid
language sql stable security definer set search_path='' as $$ select auth.uid() $$;
revoke all on function private.session_actor() from public,anon,authenticated,service_role;
grant execute on function private.session_actor() to assistae_identity_api;
create or replace function private.require_actor() returns uuid
language plpgsql security invoker set search_path='' as $$
declare actor uuid:=private.session_actor();
begin
 if actor is null then raise exception using message='UNAUTHENTICATED',errcode='P0001'; end if;
 perform 1 from private.beta_testers where user_id=actor and enabled for share;
 if not found then raise exception using message='FORBIDDEN',errcode='P0001'; end if;
 return actor;
end $$;
grant assistae_identity_api to postgres with inherit false, set true;
