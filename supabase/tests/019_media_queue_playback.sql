begin;
do $test$
declare
 a uuid:=gen_random_uuid(); b uuid:=gen_random_uuid(); ac uuid; bc uuid;
 room_ uuid; am uuid; bm uuid; verified_ uuid; unknown_ uuid; stale_ uuid;
 first_ uuid; second_ uuid; third_ uuid; request_ uuid:=gen_random_uuid();
 src text:='https://example.com/test.mp4'; r jsonb; current_ uuid; removed_ uuid; i integer;
begin
 insert into auth.users(id) values(a),(b);
 insert into private.beta_testers(user_id) values(a),(b);
 set local role authenticated;
 perform set_config('request.jwt.claim.sub',a::text,true);
 perform public.ensure_profile('Ana');
 ac:=(public.get_command_context()->'data'->>'command_context_id')::uuid;
 r:=public.create_room('Teste fila',true,ac,gen_random_uuid());
 room_:=(r->'data'->>'room_id')::uuid; am:=(r->'data'->>'membership_id')::uuid;
 r:=public.start_queue(room_,am,1,0,0,ac,gen_random_uuid());
 assert r->>'code'='INVALID_INPUT','empty queue start should fail';
 r:=public.validate_media(room_,am,1,src,ac,gen_random_uuid());
 verified_:=(r->'data'->>'validation_id')::uuid;
 r:=public.add_to_queue(room_,am,1,src,verified_,0,ac,gen_random_uuid());
 assert r->>'code'='SOURCE_UNAVAILABLE','pending ticket admitted';
 reset role;
 unknown_:=gen_random_uuid();stale_:=gen_random_uuid();
 update private.media_validations set status='valid',kind='mp4',duration_confidence='verified',duration_ms=60000,
  source_fingerprint=repeat('a',64),assessed_at=clock_timestamp(),expires_at=clock_timestamp()+interval '5 minutes',execution_token=null
  where id=verified_;
 insert into private.media_validations(id,actor_id,room_id,membership_id,source_url,source_digest,status,kind,
  duration_confidence,source_fingerprint,assessed_at,expires_at)
 values(unknown_,a,room_,am,src,'fixture','inconclusive','mp4','inconclusive',repeat('b',64),clock_timestamp(),clock_timestamp()+interval '5 minutes'),
  (stale_,a,room_,am,src,'fixture','inconclusive','mp4','inconclusive',repeat('b',64),clock_timestamp()-interval '2 minutes',clock_timestamp()-interval '1 minute');
 set local role authenticated;
 r:=public.add_to_queue(room_,am,1,src||'?different=1',verified_,0,ac,gen_random_uuid());
 assert r->>'code'='SOURCE_UNAVAILABLE','ticket reused with different URL';
 r:=public.add_to_queue(room_,am,1,src,stale_,0,ac,gen_random_uuid());
 assert r->>'code'='SOURCE_UNAVAILABLE','expired ticket admitted';
 r:=public.add_to_queue(room_,am,1,src,verified_,0,ac,request_);
 first_:=(r->'data'->>'resource_id')::uuid;
 assert first_ is not null and r->'revisions'->>'queue_revision'='1', 'add failed '||r::text;
 r:=public.add_to_queue(room_,am,1,src,verified_,0,ac,request_);
 assert r->>'outcome'='already_applied' and r->'revisions'->>'queue_revision'='1','add replay failed';
 r:=public.add_to_queue(room_,am,1,src,unknown_,0,ac,request_);
 assert r->>'code'='IDEMPOTENCY_MISMATCH','same request with different ticket';
 r:=public.add_to_queue(room_,am,1,src,verified_,0,ac,gen_random_uuid());
 assert r->>'code'='CONFLICT','stale queue revision accepted';
 r:=public.add_to_queue(room_,am,1,src,verified_,1,ac,gen_random_uuid());second_:=(r->'data'->>'resource_id')::uuid;
 r:=public.add_to_queue(room_,am,1,src,unknown_,2,ac,gen_random_uuid());third_:=(r->'data'->>'resource_id')::uuid;
 assert second_ is not null and second_<>first_ and third_ is not null,'deliberate duplicates failed';
 r:=public.get_room_snapshot(room_,am,1);
 assert r->'data'->'playback'->>'status'='empty','adding started playback';
 r:=public.reorder_queue(room_,am,1,array[second_,second_,first_],3,ac,gen_random_uuid());
 assert r->>'code'='CONFLICT','duplicate item accepted in ordering';
 r:=public.reorder_queue(room_,am,1,array[second_,third_,first_],3,ac,gen_random_uuid());
 assert r->'revisions'->>'queue_revision'='4','reorder failed '||r::text;
 r:=public.remove_queue_item(room_,am,1,first_,4,ac,gen_random_uuid());
 assert r->'revisions'->>'queue_revision'='5','remove failed';
 r:=public.start_queue(room_,am,1,0,5,ac,gen_random_uuid());
 current_:=(r->'data'->>'resource_id')::uuid;
 assert current_ is not null and r->'revisions'->>'queue_revision'='6' and r->'revisions'->>'media_epoch'='1','initial promotion failed '||r::text;
 r:=public.set_playback(room_,am,1,'pause',null,1,1,ac,gen_random_uuid());
 assert r->'revisions'->>'playback_revision'='2','pause failed';
 r:=public.set_playback(room_,am,1,'seek',90000,2,1,ac,gen_random_uuid());
 assert r->'revisions'->>'playback_revision'='3','seek failed';
 reset role;
 assert (select status='paused' and position_ms=60000 from private.playback where room_id=room_),'seek failed to clamp or preserve pause';
 assert (select position from private.queue_items where id=third_)=1,'promotion failed to compact queue';
 perform private.advance_due_playback(100);
 assert (select status='paused' and media_epoch=1 and revision=3 from private.playback where room_id=room_),'paused media advanced';
 set local role authenticated;
 perform set_config('request.jwt.claim.sub',b::text,true);perform public.ensure_profile('Bia');
 bc:=(public.get_command_context()->'data'->>'command_context_id')::uuid;
 r:=public.join_room(jsonb_build_object('public_room_id',room_),bc,gen_random_uuid());bm:=(r->'data'->>'membership_id')::uuid;
 r:=public.set_playback(room_,bm,1,'play',null,3,1,bc,gen_random_uuid());
 assert r->>'code'='FORBIDDEN','viewer controlled playback';
 r:=public.report_media_ended(room_,bm,1,1,60000);
 assert r->>'outcome'='unchanged','valid viewer end report rejected';
 perform set_config('request.jwt.claim.sub',a::text,true);
 r:=public.advance_after_unverified_end(room_,am,1,1,3,6,ac,gen_random_uuid());
 assert r->>'code'='CONFLICT','manual command advanced verified media';
 r:=public.set_playback(room_,am,1,'play',null,3,1,ac,gen_random_uuid());
 assert r->'revisions'->>'playback_revision'='4','resume failed';
 reset role;
 perform private.advance_due_playback(100);
 assert (select status='playing' and media_epoch=2 and revision=5 and media_id<>current_ from private.playback where room_id=room_),'due worker did not promote exactly once';
 assert not exists(select from private.media_items where id=current_),'old unreferenced media remained';
 update private.playback set reference_at=clock_timestamp()-interval '1 hour' where room_id=room_;
 perform private.advance_due_playback(100);
 assert (select status='playing' and media_epoch=2 from private.playback where room_id=room_),'unknown duration advanced by timer';
 set local role authenticated;
 r:=public.advance_after_unverified_end(room_,am,1,2,5,7,ac,gen_random_uuid());
 assert r->'revisions'->>'playback_revision'='6' and r->'revisions'->>'media_epoch'='2','manual end failed';
 r:=public.set_playback(room_,am,1,'play',null,6,2,ac,gen_random_uuid());
 assert r->'revisions'->>'media_epoch'='3','replay failed';
 r:=public.play_now(room_,am,1,src,verified_,7,3,ac,gen_random_uuid());
 assert r->'revisions'->>'media_epoch'='4' and r->'revisions'->>'queue_revision'='7','play now failed';
 for i in 1..50 loop
  r:=public.add_to_queue(room_,am,1,src,verified_,i+6,ac,gen_random_uuid());
  assert r->'revisions'->>'queue_revision'=(i+7)::text,'queue addition '||i||' failed '||r::text;
 end loop;
 r:=public.add_to_queue(room_,am,1,src,verified_,57,ac,gen_random_uuid());
 assert r->>'code'='QUEUE_FULL','51st item accepted';
 r:=public.get_room_snapshot(room_,am,1);
 r:=public.close_room(room_,am,1,(r->'revisions'->>'room_revision')::bigint,ac,gen_random_uuid());
 assert r->>'outcome'='applied','close failed';
 reset role;
 assert not exists(select from private.media_items where room_id=room_)
  and not exists(select from private.media_validations where room_id=room_)
  and not exists(select from private.queue_items where room_id=room_),'room close left media data';
end $test$;
set constraints all immediate;
rollback;
select 'media_queue_playback: passed; fixtures rolled back' as result;
