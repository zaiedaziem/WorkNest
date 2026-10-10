-- Harden database functions (fixes Supabase security advisor warnings)
--
-- 1. Fix the search_path of functions that didn't set one, so a function can't
--    be tricked into using a same-named object from another schema.
-- 2. Stop exposing internal functions through the public API (/rest/v1/rpc/...):
--    trigger functions are only meant to run as triggers, and the helper
--    functions are only needed by signed-in users' row-level security policies.
--    (Triggers still fire: EXECUTE is only checked when a trigger is created.)
-- 3. Index public_holidays.company_id (unindexed foreign key).
--
-- get_login_email stays callable without signing in — the app needs it to log in.
--
-- Rollback: supabase/rollbacks/20261010030000_rollback_harden_functions.sql

begin;

-- 1. Fixed search_path
alter function public.is_app_request()              set search_path = public;
alter function public.attendance_guard_update()     set search_path = public;
alter function public.leave_request_guard_update()  set search_path = public;
alter function public.claim_guard_insert()          set search_path = public;
alter function public.claim_guard_update()          set search_path = public;
alter function public.ot_guard_insert()             set search_path = public;
alter function public.notification_guard_update()   set search_path = public;
alter function public.search_policy(vector, integer) set search_path = public;

-- 2. Trigger functions: not callable through the API by anyone
revoke execute on function public.attendance_guard_insert()       from public, anon, authenticated;
revoke execute on function public.attendance_guard_update()       from public, anon, authenticated;
revoke execute on function public.leave_request_guard_insert()    from public, anon, authenticated;
revoke execute on function public.leave_request_guard_update()    from public, anon, authenticated;
revoke execute on function public.leave_request_pending_balance() from public, anon, authenticated;
revoke execute on function public.claim_guard_insert()            from public, anon, authenticated;
revoke execute on function public.claim_guard_update()            from public, anon, authenticated;
revoke execute on function public.ot_guard_insert()               from public, anon, authenticated;
revoke execute on function public.notification_guard_update()     from public, anon, authenticated;

--    Helpers used by RLS policies / triggers: signed-in users only
revoke execute on function public.app_user_id()    from public, anon;
revoke execute on function public.app_company_id() from public, anon;
revoke execute on function public.is_app_request() from public, anon;
revoke execute on function public.company_holidays(date, date) from public, anon;
grant  execute on function public.app_user_id()    to authenticated;
grant  execute on function public.app_company_id() to authenticated;
grant  execute on function public.is_app_request() to authenticated;
grant  execute on function public.company_holidays(date, date) to authenticated;

-- 3. Index for the company days-off foreign key
create index if not exists public_holidays_company_id_idx on public.public_holidays (company_id);

commit;
