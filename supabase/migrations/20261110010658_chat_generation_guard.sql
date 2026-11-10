grant create on schema public to assistae_room_api;
set local role assistae_room_api;
create or replace function public.send_message(room_id uuid,membership_id uuid,generation bigint,chat_window_id uuid,p_body text,client_message_id uuid,command_context_id uuid,request_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $fn$
#variable_conflict use_column
declare actor uuid; room_ uuid:=room_id; member_ uuid:=membership_id; nickname_ text; payload_ jsonb; replay_ jsonb; msg_ private.messages%rowtype; seq_ bigint;
begin
 begin actor:=private.require_actor(); perform private.consume_rate(actor,'sendMessage',10,10);
 exception when sqlstate 'P0001' then return private.failure('sendMessage',sqlerrm,request_id); end;
 begin
  payload_:=jsonb_build_object('room_id',room_,'membership_id',member_,'generation',generation::text,'chat_window_id',chat_window_id,'body',p_body,'client_message_id',client_message_id);
  replay_:=private.start_command(actor,command_context_id,request_id,'sendMessage',payload_);
  if replay_ is not null then return replay_; end if;
  if p_body is null or char_length(p_body) not between 1 and 500 or btrim(p_body)='' or client_message_id is null then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
  select nickname into nickname_ from private.profiles where user_id=actor for update;
  if not found then raise exception using message='NOT_FOUND_OR_UNAVAILABLE',errcode='P0001'; end if;
  perform 1 from private.rooms where id=room_ for update;
  perform private.reconcile_room(room_);
  perform private.require_live(actor,room_,member_,generation);
  if not exists(select 1 from private.chat_windows w where w.id=chat_window_id and w.membership_id=member_ and w.room_id=room_ and w.generation=send_message.generation and w.end_at_seq is null) then raise exception using message='STALE_CONNECTION',errcode='P0001'; end if;
  perform private.require_current_context(actor,command_context_id);
  select * into msg_ from private.messages m where m.sender_id=actor and m.client_message_id=send_message.client_message_id;
  if found then
   if msg_.room_id<>room_ or msg_.sender_membership_id<>member_ or msg_.body is distinct from p_body then raise exception using message='IDEMPOTENCY_MISMATCH',errcode='P0001'; end if;
   perform private.finish_message_command(actor,command_context_id,request_id,payload_,room_,msg_.seq);
   return private.reply('sendMessage','unchanged',jsonb_build_object('room_id',room_,'seq',msg_.seq::text,'created_at',msg_.created_at),'{}',request_id);
  end if;
  update private.room_counters set last_message_seq=last_message_seq+1 where room_id=room_ returning last_message_seq into seq_;
  insert into private.messages(room_id,seq,sender_membership_id,sender_id,client_message_id,sender_nickname,body)
   values(room_,seq_,member_,actor,client_message_id,nickname_,p_body) returning * into msg_;
  perform private.finish_message_command(actor,command_context_id,request_id,payload_,room_,seq_);
  return private.reply('sendMessage','applied',jsonb_build_object('room_id',room_,'seq',seq_::text,'created_at',msg_.created_at),'{}',request_id);
 exception when sqlstate 'P0001' then return private.failure('sendMessage',sqlerrm,request_id); end;
end $fn$;
create or replace function public.list_messages(room_id uuid,membership_id uuid,generation bigint,chat_window_id uuid,after_seq bigint default null,before_seq bigint default null,limit_ integer default 50) returns jsonb
language plpgsql security definer set search_path='' as $fn$
#variable_conflict use_column
declare actor uuid; room_ uuid:=room_id; member_ uuid:=membership_id; start_ bigint; data_ jsonb;
begin
 begin actor:=private.require_actor(); perform private.consume_rate(actor,'listMessages',120,60);
 exception when sqlstate 'P0001' then return private.failure('listMessages',sqlerrm); end;
 begin
  if limit_ is null or limit_ not between 1 and 100 or (after_seq is not null and before_seq is not null)
   or after_seq<0 or before_seq<1 then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
  perform 1 from private.rooms where id=room_ for update;
  perform private.reconcile_room(room_);
  perform private.require_live(actor,room_,member_,generation);
  select w.start_after_seq into start_ from private.chat_windows w
   where w.id=chat_window_id and w.room_id=room_ and w.membership_id=member_ and w.generation=list_messages.generation and w.end_at_seq is null;
  if not found then raise exception using message='STALE_CONNECTION',errcode='P0001'; end if;
  with page as (
   select m.* from private.messages m where m.room_id=room_ and m.seq>start_ and
    (after_seq is null or m.seq>after_seq) and (before_seq is null or m.seq<before_seq)
   order by case when before_seq is not null then m.seq end desc,m.seq asc limit limit_
  )
  select jsonb_build_object('messages',coalesce(jsonb_agg(jsonb_build_object('room_id',room_id,'seq',seq::text,'sender_id',sender_id,
   'sender_membership_id',sender_membership_id,'sender_nickname',sender_nickname,'body',body,'created_at',created_at) order by seq),'[]'),
   'next_after_seq',max(seq)::text,'next_before_seq',min(seq)::text) into data_ from page;
  return private.reply('listMessages','unchanged',data_,'{}');
 exception when sqlstate 'P0001' then return private.failure('listMessages',sqlerrm); end;
end $fn$;
reset role;
revoke create on schema public from assistae_room_api;
