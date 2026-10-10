-- Let employees cancel their own pending OT requests (same rule as leave and claims)
--
-- Rollback: supabase/rollbacks/20261010040000_rollback_cancel_ot_requests.sql

begin;

create policy emp_update_own_ot on public."OtRequests" for update to authenticated
  using ("EmployeeId" = public.app_user_id()) with check ("EmployeeId" = public.app_user_id());

-- The only change an employee may make: pending → cancelled
create or replace function public.ot_guard_update() returns trigger
language plpgsql set search_path = public as $$
declare r public."OtRequests";
begin
  if not public.is_app_request() then return new; end if;
  if old."Status" <> 'pending' or new."Status" <> 'cancelled' then
    raise exception 'Only pending OT requests can be cancelled.';
  end if;
  r := old;
  r."Status" := 'cancelled';
  return r;
end $$;

revoke execute on function public.ot_guard_update() from public, anon, authenticated;

create trigger trg_ot_guard_update before update on public."OtRequests"
  for each row execute function public.ot_guard_update();

commit;
