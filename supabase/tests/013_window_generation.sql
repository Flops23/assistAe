begin;
do $test$
declare actor uuid:=gen_random_uuid(); ctx uuid; room_ uuid; member_ uuid; window_ uuid; r jsonb; read_code text; send_code text;
begin
 insert into auth.users(id) values(actor); insert into private.beta_testers(user_id) values(actor);
 perform set_config('request.jwt.claim.sub',actor::text,true); set local role authenticated;
 perform public.ensure_profile('Ana'); ctx:=(public.get_command_context()->'data'->>'command_context_id')::uuid;
 r:=public.create_room('Janela',true,ctx,gen_random_uuid()); room_:=(r->'data'->>'room_id')::uuid;
 member_:=(r->'data'->>'membership_id')::uuid; window_:=(r->'data'->>'chat_window_id')::uuid;
 reset role;
 -- Fixture administrativa inconsistente: a API deve falhar fechada.
 update private.chat_windows set generation=2 where id=window_;
 set local role authenticated;
 r:=public.list_messages(room_,member_,1,window_,0,null,10); read_code:=r->>'code';
 r:=public.send_message(room_,member_,1,window_,'Teste',gen_random_uuid(),ctx,gen_random_uuid()); send_code:=r->>'code';
 assert read_code='STALE_CONNECTION' and send_code='STALE_CONNECTION','window generation comparison bypassed';
 reset role;
 assert not exists(select 1 from private.messages where room_id=room_),'invalid window wrote message';
end
$test$;
rollback;
select 'mismatched_window_generation: passed; fixtures rolled back' as result;
