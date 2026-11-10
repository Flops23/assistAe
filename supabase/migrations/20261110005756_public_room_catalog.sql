grant create on schema public to assistae_room_api;
set local role assistae_room_api;
create function public.list_public_rooms(query text default null,cursor jsonb default null,limit_ integer default 20) returns jsonb
language plpgsql security definer set search_path='' as $fn$
declare actor uuid; at_ timestamptz; data_ jsonb; count_ integer; created_ timestamptz; id_ uuid;
begin
 begin
  actor:=private.require_actor();
  perform private.consume_rate(actor,'listPublicRooms',60,60);
 exception when sqlstate 'P0001' then return private.failure('listPublicRooms',sqlerrm); end;
 begin
  if limit_ is null or limit_ not between 1 and 50 or char_length(query)>60 then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
  if cursor is not null then
   if jsonb_typeof(cursor)<>'object' then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
   if (select count(*) from jsonb_object_keys(cursor))<>3 or not(cursor ?& array['connected_count','created_at','id']) then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
   count_:=(cursor->>'connected_count')::integer; created_:=(cursor->>'created_at')::timestamptz; id_:=(cursor->>'id')::uuid;
   if count_ is null or count_ not between 0 and 10 or created_ is null or id_ is null then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
  end if;
  at_:=clock_timestamp();
  with catalog as (
   select r.id,r.name,r.created_at,
    count(*) filter(where m.state='active' and c.detected_at is null and c.suspect_at>at_)::integer as connected_count
   from private.rooms r join private.memberships m on m.room_id=r.id and m.state<>'ended'
   join private.connections c on c.membership_id=m.id and c.grace_deadline>at_
   where r.status='active' and r.visibility='public' and (query is null or strpos(lower(r.name),lower(btrim(query)))>0)
   group by r.id
  ), page as (
   select * from catalog where cursor is null or (connected_count,created_at,id)<(count_,created_,id_)
   order by connected_count desc,created_at desc,id desc limit limit_+1
  ), visible as (
   select * from page order by connected_count desc,created_at desc,id desc limit limit_
  )
  select jsonb_build_object('rooms',(select coalesce(jsonb_agg(jsonb_build_object('id',id,'name',name,'connected_count',connected_count)
    order by connected_count desc,created_at desc,id desc),'[]') from visible),
   'next_cursor',case when (select count(*) from page)>limit_ then
    (select jsonb_build_object('connected_count',connected_count,'created_at',created_at,'id',id)
     from visible order by connected_count,created_at,id limit 1) else null end) into data_;
  return private.reply('listPublicRooms','unchanged',data_,'{}');
 exception when sqlstate 'P0001' then return private.failure('listPublicRooms',sqlerrm);
 when invalid_text_representation or invalid_datetime_format or datetime_field_overflow or numeric_value_out_of_range then
  return private.failure('listPublicRooms','INVALID_INPUT');
 end;
end $fn$;
revoke all on function public.list_public_rooms(text,jsonb,integer) from public,anon,service_role;
grant execute on function public.list_public_rooms(text,jsonb,integer) to authenticated;
reset role;
revoke create on schema public from assistae_room_api;
