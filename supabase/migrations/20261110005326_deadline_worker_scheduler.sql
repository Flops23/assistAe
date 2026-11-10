-- O novo owner precisa conceder EXECUTE administrativo após a troca de owner.
set local role assistae_room_api;
grant execute on function private.expire_rooms(integer) to postgres;
reset role;
create extension if not exists pg_cron;
select cron.schedule('assistae_expire_rooms','5 seconds','select private.expire_rooms(100)');
-- Somente histórico dos jobs assistAe, preservando jobs de outras aplicações.
select cron.schedule('assistae_cron_history','19 3 * * *',$job$
 delete from cron.job_run_details where end_time < now()-interval '7 days'
 and jobid in (select jobid from cron.job where jobname in ('assistae_expire_rooms','assistae_cron_history'));
$job$);
