begin;
do $test$
declare
 a uuid := gen_random_uuid(); b uuid := gen_random_uuid();
 fid_a text := 'c' || substr(replace(gen_random_uuid()::text,'-',''),1,21);
 fid_b text := 'd' || substr(replace(gen_random_uuid()::text,'-',''),1,21);
 request_ uuid; outbox_ uuid; claim_ jsonb; target_ jsonb; stale_ uuid; room_ uuid; invite_ uuid;
begin
 insert into auth.users(id) values(a),(b);
 insert into private.beta_testers(user_id) values(a),(b);
 insert into private.profiles(user_id,public_code,nickname) values
 (a,upper(substr(replace(a::text,'-',''),1,12)),'Pessoa A'),
 (b,upper(substr(replace(b::text,'-',''),1,12)),'Pessoa B');
 insert into private.preferences(user_id) values(a),(b);

 set local role authenticated;
 perform set_config('request.jwt.claim.sub',a::text,true);
 assert public.register_push_installation(fid_a)->>'ok'='true','register own FID';
 assert public.register_push_installation('invalid')->>'code'='INVALID_INPUT','invalid FID';
 assert public.register_push_installation(fid_a)->>'ok'='true','repeat FID';
 perform set_config('request.jwt.claim.sub',b::text,true);
 assert public.unregister_push_installation(fid_a)->>'ok'='true','idempotent removal';
 assert public.register_push_installation(fid_a)->>'code'='NOT_AVAILABLE','FID stolen';
 reset role;
 assert (select count(*)=1 from private.push_installations where user_id=a and fid=fid_a),'foreign device removed';
 assert not has_function_privilege('authenticated','public.worker_claim_push()','EXECUTE'),'client can claim outbox';
 assert not has_function_privilege('anon','public.register_push_installation(text)','EXECUTE'),'unauthenticated register';
 assert not has_table_privilege('service_role','private.push_installations','SELECT'),'generic service read';
 assert not has_schema_privilege('assistae_push_api','public','CREATE'),'push API retained CREATE';

 insert into private.friendship_pairs(user_low,user_high) values(least(a,b),greatest(a,b));
 insert into private.friendship_requests(sender_id,recipient_id,user_low,user_high)
 values(b,a,least(a,b),greatest(a,b)) returning id into request_;
 insert into private.notification_outbox(recipient_id,event_key,resource_id,kind,next_attempt_at)
 values(a,'friendship:'||request_,request_,'friendship','2000-01-01') returning id into outbox_;

 set local role service_role;
 claim_:=public.worker_claim_push();
 assert claim_->>'id'=outbox_::text and not claim_?'fid','claim discloses destination early';
 stale_:=(claim_->>'attempt')::uuid;
 target_:=public.worker_prepare_push(outbox_,stale_);
 assert target_->>'fid'=fid_a and target_->>'kind'='friend_request','eligible request failed';
 assert public.worker_finish_push(outbox_,stale_,'retry',90),'retry not recorded';
 assert not public.worker_finish_push(outbox_,stale_,'delivered',null),'stale attempt accepted';
 reset role;
 assert (select status='pending' and attempts=1 and next_attempt_at>clock_timestamp()+interval '80 seconds'
 from private.notification_outbox where id=outbox_),'retry delay ignored';

 update private.notification_outbox set next_attempt_at='2000-01-01' where id=outbox_;
 set local role service_role;
 claim_:=public.worker_claim_push();
 target_:=public.worker_prepare_push(outbox_,(claim_->>'attempt')::uuid);
 assert target_->>'fid'=fid_a,'retry target missing';
 reset role;
 set local role authenticated;
 perform set_config('request.jwt.claim.sub',a::text,true);
 assert public.register_push_installation(fid_b)->>'ok'='true','FID rotation failed';
 reset role;
 set local role service_role;
 assert public.worker_finish_push(outbox_,(claim_->>'attempt')::uuid,'unregistered',null),'invalid target result failed';
 reset role;
 assert (select fid=fid_b from private.push_installations where user_id=a),'stale invalidation removed rotated destination';
 assert (select status='pending' from private.notification_outbox where id=outbox_),'rotation did not requeue';

 update private.notification_outbox set next_attempt_at='2000-01-01' where id=outbox_;
 set local role service_role;
 claim_:=public.worker_claim_push();
 reset role;
 update private.preferences set notify_friendships=false where user_id=a;
 set local role service_role;
 assert public.worker_prepare_push(outbox_,(claim_->>'attempt')::uuid) is null,'disabled preference ignored';
 reset role;
 assert (select status='suppressed' from private.notification_outbox where id=outbox_),'suppression missing';

 insert into private.rooms(name,status,admin_state) values('Sala fechada','active','awaiting_successor') returning id into room_;
 insert into private.room_invites(room_id,sender_id,recipient_id) values(room_,b,a) returning id into invite_;
 insert into private.notification_outbox(recipient_id,event_key,resource_id,kind,next_attempt_at)
 values(a,'invite:'||invite_,invite_,'invite','2000-01-01') returning id into outbox_;
 set local role service_role;
 claim_:=public.worker_claim_push();
 reset role;
 update private.rooms set status='closed',closed_at=clock_timestamp(),admin_state='none' where id=room_;
 set local role service_role;
 assert public.worker_prepare_push(outbox_,(claim_->>'attempt')::uuid) is null,'closed room notified';
 reset role;
 assert (select status='suppressed' from private.notification_outbox where id=outbox_),'closed room not suppressed';

 update private.preferences set notify_friendships=true where user_id=a;
 update private.notification_outbox set status='pending',next_attempt_at='2000-01-01'
 where resource_id=request_ and kind='friendship' returning id into outbox_;
 set local role service_role;
 claim_:=public.worker_claim_push();
 stale_:=(claim_->>'attempt')::uuid;
 reset role;
 update private.notification_outbox set lease_until='2000-01-01' where id=outbox_;
 set local role service_role;
 assert public.worker_prepare_push(outbox_,stale_) is null,'expired lease can send';
 assert not public.worker_finish_push(outbox_,stale_,'delivered',null),'expired lease can finalize';
 assert public.worker_claim_push() is null,'exhausted item was reclaimed';
 reset role;
 assert (select status='failed' and attempts=4 from private.notification_outbox where id=outbox_),'exhausted lease still active';

 update private.notification_outbox set status='pending',attempts=0,next_attempt_at='2000-01-01'
 where id=outbox_;
 set local role service_role;
 claim_:=public.worker_claim_push();
 target_:=public.worker_prepare_push(outbox_,(claim_->>'attempt')::uuid);
 assert target_->>'fid'=fid_b,'rotated device not used';
 assert public.worker_finish_push(outbox_,(claim_->>'attempt')::uuid,'delivered',null),'delivery not recorded';
 reset role;
 assert (select status='delivered' and delivered_at is not null from private.notification_outbox where id=outbox_),'delivery state missing';

 set local role authenticated;
 perform set_config('request.jwt.claim.sub',a::text,true);
 assert public.unregister_push_installation(fid_a)->>'ok'='true','stale removal failed';
 assert public.unregister_push_installation(fid_b)->>'ok'='true','own removal failed';
 assert public.unregister_push_installation(fid_b)->>'ok'='true','repeat removal failed';
 reset role;
 assert not exists(select 1 from private.push_installations where user_id=a),'destination still registered';
end
$test$;
rollback;
select 'push_dispatcher: passed; fixtures rolled back; no FCM request' as result;
