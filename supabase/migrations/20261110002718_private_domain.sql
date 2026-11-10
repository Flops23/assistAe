-- assistAe: domínio privado. Operações de sala serão liberadas por migrações posteriores.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated, service_role;
alter default privileges in schema private revoke all on tables from public, anon, authenticated, service_role;
alter default privileges in schema private revoke all on sequences from public, anon, authenticated, service_role;
-- O default global PUBLIC precisa ser removido globalmente, não só no schema.
alter default privileges revoke execute on functions from public;
alter default privileges in schema public revoke execute on functions from anon, authenticated, service_role;
alter default privileges in schema private revoke execute on functions from anon, authenticated, service_role;

create table private.beta_testers (
 user_id uuid primary key references auth.users(id),
 enabled boolean not null default true,
 created_at timestamptz not null default clock_timestamp()
);
create table private.profiles (
 user_id uuid primary key references auth.users(id),
 public_code text not null unique check(public_code ~ '^[A-F0-9]{12}$'),
 nickname text not null check(char_length(nickname) between 2 and 24 and nickname=btrim(nickname)),
 revision bigint not null default 0 check(revision>=0),
 created_at timestamptz not null default clock_timestamp(),
 updated_at timestamptz not null default clock_timestamp()
);
create table private.preferences (
 user_id uuid primary key references private.profiles(user_id),
 overlay_position text not null default 'bottom' check(overlay_position in ('top','bottom')),
 overlay_size_key text not null default 'small' check(overlay_size_key in ('small','medium','large')),
 overlay_speed_key text not null default 'normal' check(overlay_speed_key in ('slow','normal','fast')),
 notify_invites boolean not null default true,
 notify_friendships boolean not null default true,
 revision bigint not null default 0 check(revision>=0),
 updated_at timestamptz not null default clock_timestamp()
);
create table private.rooms (
 id uuid primary key default gen_random_uuid(),
 name text not null check(char_length(name) between 2 and 60 and name=btrim(name)),
 visibility text not null default 'public' check(visibility in ('public','private')),
 status text not null default 'active' check(status in ('active','closed')),
 admin_state text not null default 'assigned' check(admin_state in ('assigned','awaiting_successor','none')),
 admin_membership_id uuid,
 revision bigint not null default 0 check(revision>=0),
 created_at timestamptz not null default clock_timestamp(),
 closed_at timestamptz,
 check((status='active' and closed_at is null and
   ((admin_state='assigned' and admin_membership_id is not null) or
    (admin_state='awaiting_successor' and admin_membership_id is null)))
   or (status='closed' and closed_at is not null and admin_state='none' and admin_membership_id is null))
);
create table private.room_codes (
 room_id uuid primary key references private.rooms(id),
 code text not null unique check(code ~ '^[A-F0-9]{12}$'),
 invalidated_at timestamptz
);
create table private.memberships (
 id uuid primary key default gen_random_uuid(),
 room_id uuid not null references private.rooms(id),
 user_id uuid not null references private.profiles(user_id),
 join_order bigint not null check(join_order>=1),
 joined_at timestamptz not null default clock_timestamp(),
 state text not null default 'active' check(state in ('active','grace','ended')),
 can_control boolean not null default false,
 ended_at timestamptz, end_reason text,
 unique(room_id,join_order), unique(room_id,id), unique(room_id,id,user_id),
 check((state='ended' and ended_at is not null and end_reason is not null)
   or (state<>'ended' and ended_at is null and end_reason is null))
);
create unique index memberships_one_room on private.memberships(user_id) where state in ('active','grace');
create index memberships_room_state_order on private.memberships(room_id,state,join_order);
create index memberships_user on private.memberships(user_id);
alter table private.rooms add constraint rooms_admin_same_room
 foreign key(id,admin_membership_id) references private.memberships(room_id,id) deferrable initially deferred;
create index rooms_admin on private.rooms(id,admin_membership_id);
create index rooms_public_catalog on private.rooms(created_at desc,id) where status='active' and visibility='public';
create table private.connections (
 membership_id uuid primary key references private.memberships(id),
 generation bigint not null default 1 check(generation>=1),
 last_heartbeat_seq bigint not null default 0 check(last_heartbeat_seq>=0),
 last_seen_at timestamptz not null,
 suspect_at timestamptz not null,
 detected_at timestamptz,
 detection_source text check(detection_source in ('silence','transport')),
 grace_deadline timestamptz not null,
 check(suspect_at>=last_seen_at),
 check((detected_at is null and detection_source is null and grace_deadline=suspect_at+interval '60 seconds')
   or (detected_at is not null and detection_source is not null and grace_deadline=detected_at+interval '60 seconds'))
);
create index connections_deadline on private.connections(grace_deadline);
create table private.room_bans (
 room_id uuid not null references private.rooms(id),
 user_id uuid not null references private.profiles(user_id),
 actor_id uuid not null references private.profiles(user_id),
 created_at timestamptz not null default clock_timestamp(),
 primary key(room_id,user_id)
);
create index room_bans_user on private.room_bans(user_id);
create index room_bans_actor on private.room_bans(actor_id);
create table private.room_counters (
 room_id uuid primary key references private.rooms(id),
 last_message_seq bigint not null default 0 check(last_message_seq>=0),
 last_join_order bigint not null default 0 check(last_join_order>=0),
 queue_revision bigint not null default 0 check(queue_revision>=0)
);
create table private.chat_windows (
 id uuid primary key default gen_random_uuid(),
 room_id uuid not null,
 membership_id uuid not null,
 generation bigint not null check(generation>=1),
 start_after_seq bigint not null check(start_after_seq>=0),
 end_at_seq bigint,
 created_at timestamptz not null default clock_timestamp(),
 foreign key(room_id,membership_id) references private.memberships(room_id,id),
 check(end_at_seq is null or end_at_seq>=start_after_seq)
);
create unique index chat_windows_one_open on private.chat_windows(membership_id) where end_at_seq is null;
create index chat_windows_membership on private.chat_windows(room_id,membership_id);
create table private.media_validations (
 id uuid primary key default gen_random_uuid(),
 actor_id uuid not null references private.profiles(user_id),
 room_id uuid not null,
 membership_id uuid not null,
 source_url text not null check(source_url ~* '^https?://'),
 source_digest text not null,
 status text not null default 'pending' check(status in ('pending','valid','invalid','inconclusive','expired')),
 kind text check(kind in ('mp4','hls')),
 title text,
 duration_ms bigint check(duration_ms>0),
 duration_confidence text check(duration_confidence in ('verified','inconclusive')),
 source_fingerprint text,
 assessed_at timestamptz,
 expires_at timestamptz,
 created_at timestamptz not null default clock_timestamp(),
 unique(room_id,id),
 foreign key(room_id,membership_id,actor_id) references private.memberships(room_id,id,user_id),
 check(status not in ('valid','inconclusive') or
   (kind is not null and duration_confidence is not null and assessed_at is not null and expires_at>assessed_at)),
 check(duration_confidence is distinct from 'verified' or (status in ('valid','expired') and duration_ms is not null)),
 check(status<>'inconclusive' or duration_confidence='inconclusive')
);
create index media_validations_actor on private.media_validations(actor_id);
create index media_validations_membership on private.media_validations(room_id,membership_id,actor_id);
create index media_validations_expiry on private.media_validations(expires_at);
create table private.media_items (
 id uuid primary key default gen_random_uuid(),
 room_id uuid not null references private.rooms(id),
 validation_id uuid not null,
 source_url text not null check(source_url ~* '^https?://'),
 kind text not null check(kind in ('mp4','hls')),
 title text,
 duration_ms bigint check(duration_ms>0),
 duration_confidence text not null check(duration_confidence in ('verified','inconclusive')),
 source_fingerprint text,
 assessed_at timestamptz not null,
 created_at timestamptz not null default clock_timestamp(),
 created_by uuid not null references private.profiles(user_id),
 unique(room_id,id),
 foreign key(room_id,validation_id) references private.media_validations(room_id,id),
 check(duration_confidence<>'verified' or duration_ms is not null)
);
create index media_items_validation on private.media_items(room_id,validation_id);
create index media_items_creator on private.media_items(created_by);
create table private.playback (
 room_id uuid primary key references private.rooms(id),
 media_id uuid,
 media_epoch bigint not null default 0 check(media_epoch>=0),
 status text not null default 'empty' check(status in ('empty','paused','playing','ended')),
 position_ms bigint not null default 0 check(position_ms>=0),
 reference_at timestamptz not null default clock_timestamp(),
 revision bigint not null default 0 check(revision>=0),
 foreign key(room_id,media_id) references private.media_items(room_id,id),
 check((status='empty' and media_id is null and position_ms=0) or (status<>'empty' and media_id is not null))
);
create index playback_media on private.playback(room_id,media_id);
create table private.queue_items (
 id uuid primary key default gen_random_uuid(),
 room_id uuid not null references private.rooms(id),
 media_id uuid not null,
 position integer not null check(position>=1),
 added_by uuid not null references private.profiles(user_id),
 created_at timestamptz not null default clock_timestamp(),
 unique(room_id,position) deferrable initially deferred,
 foreign key(room_id,media_id) references private.media_items(room_id,id)
);
create index queue_items_media on private.queue_items(room_id,media_id);
create index queue_items_actor on private.queue_items(added_by);
create table private.messages (
 room_id uuid not null,
 seq bigint not null check(seq>=1),
 sender_membership_id uuid not null,
 sender_id uuid not null,
 client_message_id uuid not null,
 sender_nickname text not null check(char_length(sender_nickname) between 2 and 24),
 body text not null check(char_length(body) between 1 and 500 and btrim(body)<>''),
 created_at timestamptz not null default clock_timestamp(),
 primary key(room_id,seq),
 unique(sender_id,client_message_id),
 foreign key(room_id,sender_membership_id,sender_id) references private.memberships(room_id,id,user_id)
);
create index messages_sender_membership on private.messages(room_id,sender_membership_id,sender_id);
create table private.friendship_pairs (
 user_low uuid not null references private.profiles(user_id),
 user_high uuid not null references private.profiles(user_id),
 created_at timestamptz not null default clock_timestamp(),
 primary key(user_low,user_high),
 check(user_low<user_high)
);
create index friendship_pairs_high on private.friendship_pairs(user_high);
create table private.friendship_requests (
 id uuid primary key default gen_random_uuid(),
 sender_id uuid not null references private.profiles(user_id),
 recipient_id uuid not null references private.profiles(user_id),
 user_low uuid not null, user_high uuid not null,
 status text not null default 'pending' check(status in ('pending','accepted','rejected','cancelled')),
 created_at timestamptz not null default clock_timestamp(), resolved_at timestamptz,
 foreign key(user_low,user_high) references private.friendship_pairs(user_low,user_high),
 check(user_low=least(sender_id,recipient_id) and user_high=greatest(sender_id,recipient_id) and sender_id<>recipient_id),
 check((status='pending' and resolved_at is null) or (status<>'pending' and resolved_at is not null))
);
create unique index friendship_requests_one_pending on private.friendship_requests(user_low,user_high) where status='pending';
create index friendship_requests_pair on private.friendship_requests(user_low,user_high);
create index friendship_requests_recipient on private.friendship_requests(recipient_id,status,created_at,id);
create index friendship_requests_sender on private.friendship_requests(sender_id,status,created_at,id);
create table private.friendships (
 user_low uuid not null, user_high uuid not null,
 created_at timestamptz not null default clock_timestamp(),
 primary key(user_low,user_high),
 foreign key(user_low,user_high) references private.friendship_pairs(user_low,user_high)
);
create index friendships_high on private.friendships(user_high);
create table private.room_invites (
 id uuid primary key default gen_random_uuid(),
 room_id uuid not null references private.rooms(id),
 sender_id uuid not null references private.profiles(user_id),
 recipient_id uuid not null references private.profiles(user_id),
 status text not null default 'pending' check(status in ('pending','used','room_closed')),
 created_at timestamptz not null default clock_timestamp(), used_at timestamptz,
 check(sender_id<>recipient_id),
 check((status='used' and used_at is not null) or (status<>'used' and used_at is null))
);
create unique index room_invites_one_pending on private.room_invites(room_id,recipient_id) where status='pending';
create index room_invites_room on private.room_invites(room_id);
create index room_invites_recipient on private.room_invites(recipient_id,status,created_at,id);
create index room_invites_sender on private.room_invites(sender_id);
create table private.command_contexts (
 id uuid primary key default gen_random_uuid(),
 actor_id uuid not null references private.profiles(user_id),
 contract_version text not null default '1',
 issued_at timestamptz not null default clock_timestamp(),
 expires_at timestamptz not null,
 revoked_at timestamptz,
 unique(actor_id,id),
 check(expires_at>issued_at)
);
create index command_contexts_expiry on private.command_contexts(expires_at);
create table private.command_receipts (
 actor_id uuid not null,
 request_id uuid not null,
 command_context_id uuid not null,
 operation text not null, payload_hash text not null,
 resource_id uuid, result_code text not null,
 result_revision bigint check(result_revision>=0),
 created_at timestamptz not null default clock_timestamp(),
 expires_at timestamptz not null,
 primary key(actor_id,request_id),
 foreign key(actor_id,command_context_id) references private.command_contexts(actor_id,id),
 check(expires_at>created_at)
);
create index command_receipts_context on private.command_receipts(actor_id,command_context_id);
create index command_receipts_expiry on private.command_receipts(expires_at);
create table private.rate_buckets (
 subject_key text not null, operation text not null,
 tokens numeric not null check(tokens>=0),
 updated_at timestamptz not null default clock_timestamp(),
 primary key(subject_key,operation)
);
create table private.notification_outbox (
 id uuid primary key default gen_random_uuid(),
 recipient_id uuid not null references private.profiles(user_id),
 event_key text not null unique,
 resource_id uuid not null,
 kind text not null check(kind in ('invite','friendship')),
 status text not null default 'pending' check(status in ('pending','leased','delivered','failed','suppressed')),
 attempts integer not null default 0 check(attempts>=0),
 next_attempt_at timestamptz not null default clock_timestamp(),
 created_at timestamptz not null default clock_timestamp(),
 lease_until timestamptz, attempt_token uuid, delivered_at timestamptz,
 check((status='leased' and lease_until is not null and attempt_token is not null)
  or (status<>'leased' and lease_until is null and attempt_token is null)),
 check((status='delivered')=(delivered_at is not null))
);
create index notification_outbox_recipient on private.notification_outbox(recipient_id);
create index notification_outbox_pending on private.notification_outbox(next_attempt_at,id) where status='pending';
create index notification_outbox_leased on private.notification_outbox(lease_until,id) where status='leased';

-- Nenhum CRUD genérico, inclusive via service_role. Workers ganharão grants pontuais.
do $security$
declare item record;
begin
 for item in select tablename from pg_tables where schemaname='private' loop
  execute format('alter table private.%I enable row level security',item.tablename);
 end loop;
end
$security$;
revoke all on all tables in schema private from public, anon, authenticated, service_role;
revoke all on all sequences in schema private from public, anon, authenticated, service_role;
comment on schema private is 'assistAe: domínio interno; acesso de app somente por RPC autenticada e autorizada.';
