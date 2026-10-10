-- ROLLBACK for 20261010030000_harden_functions.sql
-- Restores the default EXECUTE privileges and unsets the fixed search_path.
begin;

do $$
declare f text;
begin
  foreach f in array array[
    'public.attendance_guard_insert()', 'public.attendance_guard_update()',
    'public.leave_request_guard_insert()', 'public.leave_request_guard_update()',
    'public.leave_request_pending_balance()', 'public.claim_guard_insert()',
    'public.claim_guard_update()', 'public.ot_guard_insert()',
    'public.notification_guard_update()', 'public.app_user_id()',
    'public.app_company_id()', 'public.is_app_request()',
    'public.company_holidays(date, date)']
  loop
    execute format('grant execute on function %s to public, anon, authenticated', f);
  end loop;
end $$;

alter function public.is_app_request()              reset search_path;
alter function public.attendance_guard_update()     reset search_path;
alter function public.leave_request_guard_update()  reset search_path;
alter function public.claim_guard_insert()          reset search_path;
alter function public.claim_guard_update()          reset search_path;
alter function public.ot_guard_insert()             reset search_path;
alter function public.notification_guard_update()   reset search_path;
alter function public.search_policy(vector, integer) reset search_path;

drop index if exists public.public_holidays_company_id_idx;

commit;
