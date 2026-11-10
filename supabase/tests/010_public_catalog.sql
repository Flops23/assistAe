begin;
do $test$
declare actor uuid; ctx uuid; r jsonb; rooms_ uuid[]:='{}'; members_ uuid[]:='{}'; cursor_ jsonb; public_ boolean;
begin
 assert to_regprocedure('public.list_public_rooms(text,jsonb,integer)') is not null,'catalog API missing';
 for i in 1..4 loop
  actor:=gen_random_uuid();
  insert into auth.users(id) values(actor);
  insert into private.beta_testers(user_id) values(actor);
  perform set_config('request.jwt.claim.sub',actor::text,true);
  set local role authenticated;
  perform public.ensure_profile('Pessoa '||i);
  ctx:=(public.get_command_context()->'data'->>'command_context_id')::uuid;
  if i<4 then
   public_:=(i<>3);
   r:=public.create_room(case i when 1 then 'Alpha' when 2 then 'Beta' else 'Privada' end,public_,ctx,gen_random_uuid());
   rooms_:=array_append(rooms_,(r->'data'->>'room_id')::uuid);
  else
   r:=public.join_room(jsonb_build_object('public_room_id',rooms_[1]),ctx,gen_random_uuid());
   members_:=array_append(members_,(r->'data'->>'membership_id')::uuid);
  end if;
  reset role;
 end loop;
 set local role authenticated;
 r:=public.list_public_rooms(null,null,1);
 assert jsonb_array_length(r->'data'->'rooms')=1,'catalog limit';
 assert r->'data'->'rooms'->0->>'id'=rooms_[1]::text,'catalog not ranked by connected count';
 assert r->'data'->'rooms'->0->>'connected_count'='2','connected count wrong';
 assert not (r->'data'->'rooms'->0 ? 'code') and not (r->'data'->'rooms'->0 ? 'source_url'),'catalog leaked private data';
 cursor_:=r->'data'->'next_cursor';
 r:=public.list_public_rooms(null,cursor_,1);
 assert r->'data'->'rooms'->0->>'id'=rooms_[2]::text,'keyset pagination wrong';
 assert jsonb_array_length(r->'data'->'rooms')=1,'private room appeared';
 r:=public.list_public_rooms('ALP',null,20);
 assert jsonb_array_length(r->'data'->'rooms')=1 and r->'data'->'rooms'->0->>'name'='Alpha','case insensitive search';
 r:=public.list_public_rooms('sem resultado',null,20);
 assert jsonb_array_length(r->'data'->'rooms')=0,'empty search result wrong';
 r:=public.list_public_rooms(null,null,0);
 assert r->>'code'='INVALID_INPUT','invalid limit accepted';
 reset role;
 update private.connections set last_seen_at=statement_timestamp()-interval '30 seconds',suspect_at=statement_timestamp()-interval '5 seconds',
  grace_deadline=statement_timestamp()+interval '55 seconds' where membership_id=members_[1];
 set local role authenticated;
 r:=public.list_public_rooms('Alpha',null,20);
 assert r->'data'->'rooms'->0->>'connected_count'='1','catalog counted reservation as connected';
 reset role;
end
$test$;
rollback;
select 'public_catalog: passed; fixtures rolled back' as result;
