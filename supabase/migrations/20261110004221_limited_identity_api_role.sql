-- Papel sem login/bypass/DDL para as seis RPCs de identidade.
create role assistae_identity_api nologin noinherit nosuperuser nocreatedb nocreaterole noreplication nobypassrls;
grant assistae_identity_api to postgres;
grant usage on schema public,private,auth to assistae_identity_api;
grant execute on function auth.uid() to assistae_identity_api;
grant execute on function private.require_actor(),private.consume_rate(uuid,text,numeric,numeric),
 private.reply(text,text,jsonb,jsonb,uuid),private.preferences_data(uuid),private.profile_data(uuid),
 private.start_command(uuid,uuid,uuid,text,jsonb),private.finish_command(uuid,uuid,uuid,text,jsonb,bigint),
 private.failure(text,text,uuid),private.require_current_context(uuid,uuid) to assistae_identity_api;
grant select on private.beta_testers,private.profiles,private.preferences,private.command_contexts,private.command_receipts,private.rate_buckets to assistae_identity_api;
grant insert on private.profiles,private.preferences,private.command_contexts,private.command_receipts,private.rate_buckets to assistae_identity_api;
grant update on private.profiles,private.preferences,private.rate_buckets to assistae_identity_api;
-- FOR SHARE exige privilégio UPDATE; CHECK false impede DML real nestes dois registros.
grant update(enabled) on private.beta_testers to assistae_identity_api;
grant update(expires_at) on private.command_contexts to assistae_identity_api;
create policy identity_beta_read on private.beta_testers for select to assistae_identity_api using(user_id=(select auth.uid()));
create policy identity_beta_lock on private.beta_testers for update to assistae_identity_api using(user_id=(select auth.uid())) with check(false);
create policy identity_profile_read on private.profiles for select to assistae_identity_api using(user_id=(select auth.uid()));
create policy identity_profile_insert on private.profiles for insert to assistae_identity_api with check(user_id=(select auth.uid()));
create policy identity_profile_update on private.profiles for update to assistae_identity_api using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy identity_preferences_read on private.preferences for select to assistae_identity_api using(user_id=(select auth.uid()));
create policy identity_preferences_insert on private.preferences for insert to assistae_identity_api with check(user_id=(select auth.uid()));
create policy identity_preferences_update on private.preferences for update to assistae_identity_api using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy identity_context_read on private.command_contexts for select to assistae_identity_api using(actor_id=(select auth.uid()));
create policy identity_context_insert on private.command_contexts for insert to assistae_identity_api with check(actor_id=(select auth.uid()));
create policy identity_context_lock on private.command_contexts for update to assistae_identity_api using(actor_id=(select auth.uid())) with check(false);
create policy identity_receipt_read on private.command_receipts for select to assistae_identity_api using(actor_id=(select auth.uid()));
create policy identity_receipt_insert on private.command_receipts for insert to assistae_identity_api with check(actor_id=(select auth.uid()));
create policy identity_bucket_read on private.rate_buckets for select to assistae_identity_api using(subject_key=(select auth.uid())::text);
create policy identity_bucket_insert on private.rate_buckets for insert to assistae_identity_api with check(subject_key=(select auth.uid())::text);
create policy identity_bucket_update on private.rate_buckets for update to assistae_identity_api using(subject_key=(select auth.uid())::text) with check(subject_key=(select auth.uid())::text);
grant create on schema public to assistae_identity_api;
alter function public.ensure_profile(text) owner to assistae_identity_api;
alter function public.get_my_profile() owner to assistae_identity_api;
alter function public.get_command_context() owner to assistae_identity_api;
alter function public.change_nickname(text,bigint,uuid,uuid) owner to assistae_identity_api;
alter function public.set_notification_preference(text,boolean,bigint,uuid,uuid) owner to assistae_identity_api;
alter function public.save_message_preferences(text,text,text,bigint,uuid,uuid) owner to assistae_identity_api;
revoke create on schema public from assistae_identity_api;
revoke assistae_identity_api from postgres;
