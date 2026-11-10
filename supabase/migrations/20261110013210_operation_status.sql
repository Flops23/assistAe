grant create on schema public to assistae_identity_api;
set local role assistae_identity_api;
create function public.get_operation_status(request_id uuid,command_context_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $fn$
declare actor uuid; receipt_ private.command_receipts%rowtype; data_ jsonb;
begin
 begin actor:=private.require_actor(); perform private.consume_rate(actor,'getOperationStatus',60,60);
 exception when sqlstate 'P0001' then return private.failure('getOperationStatus',sqlerrm); end;
 begin
  if request_id is null or command_context_id is null then raise exception using message='INVALID_INPUT',errcode='P0001'; end if;
  select * into receipt_ from private.command_receipts r where r.actor_id=actor and r.request_id=get_operation_status.request_id;
  if found then
   if receipt_.command_context_id<>command_context_id then raise exception using message='IDEMPOTENCY_MISMATCH',errcode='P0001'; end if;
   data_:=jsonb_build_object('status','applied','operation',receipt_.operation,'resource_id',receipt_.resource_id,
    'result_code',receipt_.result_code,'result_revision',receipt_.result_revision::text);
  else
   data_:=jsonb_build_object('status',case when exists(select 1 from private.command_contexts c where c.id=command_context_id and c.actor_id=actor
    and c.revoked_at is null and c.contract_version='1' and c.expires_at>clock_timestamp()) then 'unknown' else 'expired' end);
  end if;
  return private.reply('getOperationStatus','unchanged',data_,'{}');
 exception when sqlstate 'P0001' then return private.failure('getOperationStatus',sqlerrm); end;
end $fn$;
revoke all on function public.get_operation_status(uuid,uuid) from public,anon,service_role;
grant execute on function public.get_operation_status(uuid,uuid) to authenticated;
reset role;
revoke create on schema public from assistae_identity_api;
