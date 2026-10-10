-- ROLLBACK for 20261010040000_cancel_ot_requests.sql
begin;
drop trigger if exists trg_ot_guard_update on public."OtRequests";
drop function if exists public.ot_guard_update();
drop policy if exists emp_update_own_ot on public."OtRequests";
commit;
