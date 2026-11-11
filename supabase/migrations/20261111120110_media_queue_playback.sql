create or replace function private.start_command(actor uuid, context_ uuid, request_ uuid, operation_ text, payload_ jsonb) returns jsonb
language plpgsql security invoker set search_path='' as $$
declare receipt private.command_receipts%rowtype; context_row private.command_contexts%rowtype; digest_ text; revision_key text;
begin
 if context_ is null or request_ is null then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
 digest_:=encode(sha256(convert_to(jsonb_build_object('contract_version','1','context',context_,'operation',operation_,'payload',payload_)::text,'UTF8')),'hex');
 perform pg_advisory_xact_lock(hashtextextended('command:'||actor::text||':'||request_::text,0));
 select * into receipt from private.command_receipts where actor_id=actor and request_id=request_;
 if found then
  if receipt.command_context_id<>context_ or receipt.operation<>operation_ or receipt.payload_hash<>digest_ then
   raise exception using message='IDEMPOTENCY_MISMATCH',errcode='P0001';
  end if;
  revision_key:=case when operation_='changeNickname' then 'profile_revision' when operation_ in ('setNotificationPreference','saveMessagePreferences') then 'preferences_revision' when operation_='sendMessage' then 'message_seq' when operation_ in ('addToQueue','reorderQueue','removeQueueItem') then 'queue_revision' when operation_ in ('playNow','startQueue','advanceAfterUnverifiedEnd','setPlayback') then 'playback_revision' else 'room_revision' end;
  return private.reply(operation_,'already_applied',
   jsonb_build_object('result_code',receipt.result_code,'resource_id',receipt.resource_id),
   case when receipt.result_revision is null then '{}'::jsonb else jsonb_build_object(revision_key,receipt.result_revision::text) end,request_);
 end if;
 select * into context_row from private.command_contexts where actor_id=actor and id=context_ for share;
 if not found or context_row.revoked_at is not null or context_row.contract_version<>'1' or clock_timestamp()>=context_row.expires_at then
  raise exception using message='REQUEST_EXPIRED',errcode='P0001';
 end if;
 return null;
end $$;


grant create on schema public,private to assistae_room_api;
set local role assistae_room_api;

-- All media mutations hold the room row lock before reading playback or queue state.
create function private.media_position(pb private.playback, duration_ bigint, at_ timestamptz) returns bigint
language sql immutable security invoker set search_path='' as $$
 select least(coalesce(duration_,9007199254740991), pb.position_ms::numeric +
   case when pb.status='playing' then greatest(0,floor(extract(epoch from (at_-pb.reference_at))*1000)) else 0 end)::bigint
$$;

create function private.admit_media(actor uuid, room_ uuid, member_ uuid, generation_ bigint, source_ text, validation_ uuid, at_ timestamptz) returns uuid
language plpgsql security invoker set search_path='' as $$
declare media_ uuid;
begin
 insert into private.media_items(room_id,validation_id,source_url,kind,title,duration_ms,duration_confidence,source_fingerprint,assessed_at,created_by)
 select v.room_id,v.id,v.source_url,v.kind,v.title,v.duration_ms,v.duration_confidence,v.source_fingerprint,v.assessed_at,actor
 from private.media_validations v
 where v.id=validation_ and v.actor_id=actor and v.room_id=room_ and v.membership_id=member_ and v.generation=generation_
 and v.source_url=source_ and v.status in ('valid','inconclusive') and v.expires_at>at_
 returning id into media_;
 if not found then raise exception using message='SOURCE_UNAVAILABLE',errcode='P0001';end if;
 return media_;
end $$;

create function private.delete_unused_media(room_ uuid, media_ uuid) returns void
language sql security invoker set search_path='' as $$
 delete from private.media_items m where m.room_id=room_ and m.id=media_
 and not exists(select from private.queue_items q where q.room_id=room_ and q.media_id=media_)
 and not exists(select from private.playback p where p.room_id=room_ and p.media_id=media_)
$$;

create function private.compact_media_queue(room_ uuid, position_ integer) returns void
language sql security invoker set search_path='' as $$
 update private.queue_items set position=position-1 where room_id=room_ and position>position_;
 update private.room_counters set queue_revision=queue_revision+1 where room_id=room_;
$$;

create function private.advance_media(pb private.playback, end_position_ bigint, at_ timestamptz) returns void
language plpgsql security invoker set search_path='' as $$
declare next_ private.queue_items%rowtype;
begin
 select * into next_ from private.queue_items where room_id=pb.room_id order by position limit 1;
 if found then
  delete from private.queue_items where id=next_.id;
  perform private.compact_media_queue(pb.room_id,next_.position);
  update private.playback set media_id=next_.media_id,status='playing',position_ms=0,reference_at=at_,
    media_epoch=media_epoch+1,revision=revision+1 where room_id=pb.room_id;
  perform private.delete_unused_media(pb.room_id,pb.media_id);
 elsif pb.status='empty' then
  raise exception using message='INVALID_INPUT',errcode='P0001';
 else
  update private.playback set status='ended',position_ms=end_position_,reference_at=at_,revision=revision+1 where room_id=pb.room_id;
 end if;
end $$;

create function private.media_command(
 op text, room_ uuid, member_ uuid, generation_ bigint, context_ uuid, request_ uuid,
 queue_revision_ bigint default null, playback_revision_ bigint default null, epoch_ bigint default null,
 source_ text default null, validation_ uuid default null, item_ uuid default null,
 ordered_ uuid[] default null, action_ text default null, position_ bigint default null
) returns jsonb language plpgsql security invoker set search_path='' as $$
declare
 actor uuid; payload_ jsonb; replay_ jsonb; at_ timestamptz;
 pb private.playback%rowtype; q private.queue_items%rowtype; m private.media_items%rowtype;
 queue_op boolean:=op in ('addToQueue','removeQueueItem','reorderQueue');
 check_queue boolean:=queue_op or op in ('startQueue','advanceAfterUnverifiedEnd');
 check_epoch boolean:=op in ('playNow','setPlayback','advanceAfterUnverifiedEnd');
 qrev bigint; size_ integer; resource_ uuid; new_media uuid; revisions_ jsonb; data_ jsonb;
 outcome_ text:='applied';
begin
 begin
  actor:=private.require_actor();
  perform private.consume_rate(actor,op,case when op='addToQueue' then 60 else 30 end,60);
 exception when sqlstate 'P0001' then return private.failure(op,sqlerrm,request_);end;
 begin
  if (op in ('addToQueue','playNow') and (source_ is null or octet_length(source_)>8192 or validation_ is null))
    or (op='reorderQueue' and (ordered_ is null or cardinality(ordered_)>50 or array_ndims(ordered_)>1)) then
   raise exception using message='INVALID_INPUT',errcode='P0001';
  end if;
  payload_:=jsonb_build_object('room_id',room_,'membership_id',member_,'generation',generation_::text,
   'queue_revision',queue_revision_::text,'playback_revision',playback_revision_::text,'media_epoch',epoch_::text,
   'source_url',source_,'validation_reference',validation_,'item_id',item_,'ordered_item_ids',ordered_,
   'action',action_,'position_ms',position_::text);
  replay_:=private.start_command(actor,context_,request_,op,payload_);
  if replay_ is not null then return replay_;end if;
  if op in ('addToQueue','playNow') then
   perform 1 from private.profiles where user_id=actor for update;
  end if;
  perform 1 from private.rooms where id=room_ for update;
  perform private.reconcile_room(room_);
  perform private.require_live(actor,room_,member_,generation_,'control');
  perform private.require_current_context(actor,context_);
  at_:=clock_timestamp();
  select * into strict pb from private.playback where room_id=room_;
  select queue_revision into strict qrev from private.room_counters where room_id=room_;
  if (check_queue and queue_revision_ is distinct from qrev)
    or (not queue_op and playback_revision_ is distinct from pb.revision)
    or (check_epoch and epoch_ is distinct from pb.media_epoch) then
   raise exception using message='CONFLICT',errcode='P0001';
  end if;
  if pb.media_id is not null then
   select * into strict m from private.media_items where room_id=room_ and id=pb.media_id;
  end if;

  case op
   when 'addToQueue' then
    select count(*)::integer into size_ from private.queue_items where room_id=room_;
    if size_>=50 then raise exception using message='QUEUE_FULL',errcode='P0001';end if;
    new_media:=private.admit_media(actor,room_,member_,generation_,source_,validation_,at_);
    insert into private.queue_items(room_id,media_id,position,added_by) values(room_,new_media,size_+1,actor) returning id into resource_;
    update private.room_counters set queue_revision=queue_revision+1 where room_id=room_;
   when 'playNow' then
    resource_:=private.admit_media(actor,room_,member_,generation_,source_,validation_,at_);
    update private.playback set media_id=resource_,status='playing',position_ms=0,reference_at=at_,
     media_epoch=media_epoch+1,revision=revision+1 where room_id=room_;
    perform private.delete_unused_media(room_,pb.media_id);
   when 'startQueue' then
    if pb.status<>'empty' then raise exception using message='CONFLICT',errcode='P0001';end if;
    perform private.advance_media(pb,0,at_);
   when 'advanceAfterUnverifiedEnd' then
    if pb.status<>'playing' or m.duration_confidence is distinct from 'inconclusive' then
     raise exception using message='CONFLICT',errcode='P0001';
    end if;
    perform private.advance_media(pb,private.media_position(pb,null,at_),at_);
   when 'setPlayback' then
    if action_ is null or action_ not in ('play','pause','seek')
      or (action_='seek' and (position_ is null or position_ not between 0 and 9007199254740991))
      or (action_<>'seek' and position_ is not null) then
     raise exception using message='INVALID_INPUT',errcode='P0001';
    end if;
    if pb.status='empty' or (pb.status='ended' and action_<>'play') then
     raise exception using message='INVALID_INPUT',errcode='P0001';
    end if;
    if (pb.status='playing' and action_='play') or (pb.status='paused' and action_='pause') then
     outcome_:='unchanged';
    elsif action_='play' then
     update private.playback set status='playing',position_ms=case when pb.status='ended' then 0 else pb.position_ms end,
      media_epoch=media_epoch+case when pb.status='ended' then 1 else 0 end,reference_at=at_,revision=revision+1 where room_id=room_;
    elsif action_='pause' then
     update private.playback set status='paused',position_ms=private.media_position(pb,m.duration_ms,at_),
      reference_at=at_,revision=revision+1 where room_id=room_;
    else
     update private.playback set position_ms=least(position_,coalesce(m.duration_ms,position_)),reference_at=at_,revision=revision+1 where room_id=room_;
    end if;
   when 'reorderQueue' then
    if cardinality(ordered_)<>(select count(*) from private.queue_items where room_id=room_)
      or cardinality(ordered_)<>(select count(distinct ids.id) from unnest(ordered_) ids(id))
      or exists(select from unnest(ordered_) ids(id) where not exists(
        select from private.queue_items cur where cur.room_id=room_ and cur.id=ids.id)) then
     raise exception using message='CONFLICT',errcode='P0001';
    end if;
    update private.queue_items cur set position=ids.position
    from unnest(ordered_) with ordinality ids(id,position)
    where cur.room_id=room_ and cur.id=ids.id and cur.position<>ids.position;
    if found then update private.room_counters set queue_revision=queue_revision+1 where room_id=room_;
    else outcome_:='unchanged';end if;
   when 'removeQueueItem' then
    delete from private.queue_items where room_id=room_ and id=item_ returning * into q;
    if not found then raise exception using message='CONFLICT',errcode='P0001';end if;
    perform private.compact_media_queue(room_,q.position);
    perform private.delete_unused_media(room_,q.media_id);
    resource_:=q.id;
  end case;

  select queue_revision into qrev from private.room_counters where room_id=room_;
  select * into pb from private.playback where room_id=room_;
  if not queue_op then resource_:=pb.media_id;end if;
  revisions_:=case when queue_op then jsonb_build_object('queue_revision',qrev::text)
   else jsonb_build_object('queue_revision',qrev::text,'playback_revision',pb.revision::text,'media_epoch',pb.media_epoch::text) end;
  data_:=case when op='reorderQueue' then jsonb_build_object('ordered_item_ids',ordered_)
   else jsonb_build_object('resource_id',resource_) end;
  perform private.finish_media_command(actor,context_,request_,op,payload_,resource_,case when queue_op then qrev else pb.revision end);
  return private.reply(op,outcome_,data_,revisions_,request_);
 exception when sqlstate 'P0001' then return private.failure(op,sqlerrm,request_);end;
end $$;

revoke all on function private.media_position(private.playback,bigint,timestamptz),
 private.admit_media(uuid,uuid,uuid,bigint,text,uuid,timestamptz),private.delete_unused_media(uuid,uuid),
 private.compact_media_queue(uuid,integer),private.advance_media(private.playback,bigint,timestamptz),
 private.media_command(text,uuid,uuid,bigint,uuid,uuid,bigint,bigint,bigint,text,uuid,uuid,uuid[],text,bigint)
 from public,anon,authenticated,service_role;
create function public.add_to_queue(p_room uuid,p_member uuid,p_generation bigint,source_url text,validation_reference uuid,expected_queue_revision bigint,command_context_id uuid,request_id uuid) returns jsonb
language sql security definer set search_path='' as $$
 select private.media_command('addToQueue',p_room,p_member,p_generation,command_context_id,request_id,
  queue_revision_=>expected_queue_revision,source_=>source_url,validation_=>validation_reference)
$$;
revoke all on function public.add_to_queue(uuid,uuid,bigint,text,uuid,bigint,uuid,uuid) from public,anon,service_role;
grant execute on function public.add_to_queue(uuid,uuid,bigint,text,uuid,bigint,uuid,uuid) to authenticated;

create function public.play_now(p_room uuid,p_member uuid,p_generation bigint,source_url text,validation_reference uuid,expected_playback_revision bigint,expected_media_epoch bigint,command_context_id uuid,request_id uuid) returns jsonb
language sql security definer set search_path='' as $$
 select private.media_command('playNow',p_room,p_member,p_generation,command_context_id,request_id,
  playback_revision_=>expected_playback_revision,epoch_=>expected_media_epoch,source_=>source_url,validation_=>validation_reference)
$$;
revoke all on function public.play_now(uuid,uuid,bigint,text,uuid,bigint,bigint,uuid,uuid) from public,anon,service_role;
grant execute on function public.play_now(uuid,uuid,bigint,text,uuid,bigint,bigint,uuid,uuid) to authenticated;

create function public.start_queue(p_room uuid,p_member uuid,p_generation bigint,expected_playback_revision bigint,expected_queue_revision bigint,command_context_id uuid,request_id uuid) returns jsonb
language sql security definer set search_path='' as $$
 select private.media_command('startQueue',p_room,p_member,p_generation,command_context_id,request_id,
  playback_revision_=>expected_playback_revision,queue_revision_=>expected_queue_revision)
$$;
revoke all on function public.start_queue(uuid,uuid,bigint,bigint,bigint,uuid,uuid) from public,anon,service_role;
grant execute on function public.start_queue(uuid,uuid,bigint,bigint,bigint,uuid,uuid) to authenticated;

create function public.advance_after_unverified_end(p_room uuid,p_member uuid,p_generation bigint,expected_media_epoch bigint,expected_playback_revision bigint,expected_queue_revision bigint,command_context_id uuid,request_id uuid) returns jsonb
language sql security definer set search_path='' as $$
 select private.media_command('advanceAfterUnverifiedEnd',p_room,p_member,p_generation,command_context_id,request_id,
  epoch_=>expected_media_epoch,playback_revision_=>expected_playback_revision,queue_revision_=>expected_queue_revision)
$$;
revoke all on function public.advance_after_unverified_end(uuid,uuid,bigint,bigint,bigint,bigint,uuid,uuid) from public,anon,service_role;
grant execute on function public.advance_after_unverified_end(uuid,uuid,bigint,bigint,bigint,bigint,uuid,uuid) to authenticated;

create function public.set_playback(p_room uuid,p_member uuid,p_generation bigint,action text,position_ms bigint,expected_playback_revision bigint,expected_media_epoch bigint,command_context_id uuid,request_id uuid) returns jsonb
language sql security definer set search_path='' as $$
 select private.media_command('setPlayback',p_room,p_member,p_generation,command_context_id,request_id,
  action_=>action,position_=>position_ms,playback_revision_=>expected_playback_revision,epoch_=>expected_media_epoch)
$$;
revoke all on function public.set_playback(uuid,uuid,bigint,text,bigint,bigint,bigint,uuid,uuid) from public,anon,service_role;
grant execute on function public.set_playback(uuid,uuid,bigint,text,bigint,bigint,bigint,uuid,uuid) to authenticated;

create function public.reorder_queue(p_room uuid,p_member uuid,p_generation bigint,ordered_item_ids uuid[],expected_queue_revision bigint,command_context_id uuid,request_id uuid) returns jsonb
language sql security definer set search_path='' as $$
 select private.media_command('reorderQueue',p_room,p_member,p_generation,command_context_id,request_id,
  ordered_=>ordered_item_ids,queue_revision_=>expected_queue_revision)
$$;
revoke all on function public.reorder_queue(uuid,uuid,bigint,uuid[],bigint,uuid,uuid) from public,anon,service_role;
grant execute on function public.reorder_queue(uuid,uuid,bigint,uuid[],bigint,uuid,uuid) to authenticated;

create function public.remove_queue_item(p_room uuid,p_member uuid,p_generation bigint,item_id uuid,expected_queue_revision bigint,command_context_id uuid,request_id uuid) returns jsonb
language sql security definer set search_path='' as $$
 select private.media_command('removeQueueItem',p_room,p_member,p_generation,command_context_id,request_id,
  item_=>item_id,queue_revision_=>expected_queue_revision)
$$;
revoke all on function public.remove_queue_item(uuid,uuid,bigint,uuid,bigint,uuid,uuid) from public,anon,service_role;
grant execute on function public.remove_queue_item(uuid,uuid,bigint,uuid,bigint,uuid,uuid) to authenticated;

create function public.report_media_ended(p_room uuid,p_member uuid,p_generation bigint,media_epoch bigint,observed_position_ms bigint) returns jsonb
language plpgsql security definer set search_path='' as $$
declare actor uuid;
begin
 begin
  actor:=private.require_actor();
  perform private.consume_rate(actor,'reportMediaEnded',30,60);
 exception when sqlstate 'P0001' then return private.failure('reportMediaEnded',sqlerrm);end;
 begin
  if media_epoch is null or media_epoch<0 or observed_position_ms is null or observed_position_ms not between 0 and 9007199254740991 then
   raise exception using message='INVALID_INPUT',errcode='P0001';
  end if;
  perform 1 from private.rooms where id=p_room for update;
  perform private.reconcile_room(p_room);
  perform private.require_live(actor,p_room,p_member,p_generation);
  if not exists(select from private.playback p where p.room_id=p_room and p.media_epoch=report_media_ended.media_epoch) then
   raise exception using message='CONFLICT',errcode='P0001';
  end if;
  return private.reply('reportMediaEnded','unchanged','{}','{}');
 exception when sqlstate 'P0001' then return private.failure('reportMediaEnded',sqlerrm);end;
end $$;
revoke all on function public.report_media_ended(uuid,uuid,bigint,bigint,bigint) from public,anon,service_role;
grant execute on function public.report_media_ended(uuid,uuid,bigint,bigint,bigint) to authenticated;

create function private.advance_due_playback(limit_ integer default 100) returns integer
language plpgsql security definer set search_path='' as $$
declare room_ uuid; pb private.playback%rowtype; duration_ bigint; at_ timestamptz; changed_ integer:=0;
begin
 for room_ in
  select r.id from private.rooms r join private.playback p on p.room_id=r.id
  join private.media_items m on m.room_id=r.id and m.id=p.media_id
  where r.status='active' and p.status='playing' and m.duration_confidence='verified'
   and private.media_position(p,m.duration_ms,statement_timestamp())>=m.duration_ms
  order by r.id limit least(100,greatest(0,limit_)) for update of r skip locked
 loop
  perform private.reconcile_room(room_);
  select * into pb from private.playback where room_id=room_;
  if pb.status<>'playing' then continue;end if;
  select duration_ms into duration_ from private.media_items where room_id=room_ and id=pb.media_id and duration_confidence='verified';
  at_:=clock_timestamp();
  if duration_ is not null and private.media_position(pb,duration_,at_)>=duration_ then
   perform private.advance_media(pb,duration_,at_);
   changed_:=changed_+1;
  end if;
 end loop;
 return changed_;
end $$;
revoke all on function private.advance_due_playback(integer) from public,anon,authenticated,service_role;
grant execute on function private.advance_due_playback(integer) to postgres;

reset role;
revoke create on schema public,private from assistae_room_api;
select cron.schedule('assistae_advance_playback','5 seconds','select private.advance_due_playback(100)');
select cron.schedule('assistae_cron_history','19 3 * * *',$job$
 delete from cron.job_run_details where end_time < now()-interval '7 days'
 and jobid in (select jobid from cron.job where jobname in ('assistae_expire_rooms','assistae_advance_playback','assistae_cron_history'));
$job$);
