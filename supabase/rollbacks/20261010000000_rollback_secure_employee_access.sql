-- ROLLBACK for 20261010000000_secure_employee_access.sql
-- Restores the original (open) row-level security policies and removes the
-- triggers/helper functions added by that migration. Only run this if the
-- migration breaks something and you need the old behaviour back.

begin;

-- ── Drop triggers ────────────────────────────────────────────────────────────
drop trigger if exists trg_attendance_guard_insert on public.attendance;
drop trigger if exists trg_attendance_guard_update on public.attendance;
drop trigger if exists trg_leave_request_guard_insert on public.leave_requests;
drop trigger if exists trg_leave_request_guard_update on public.leave_requests;
drop trigger if exists trg_leave_request_pending_balance on public.leave_requests;
drop trigger if exists trg_claim_guard_insert on public."ClaimRequests";
drop trigger if exists trg_claim_guard_update on public."ClaimRequests";
drop trigger if exists trg_ot_guard_insert on public."OtRequests";
drop trigger if exists trg_notification_guard_update on public."Notifications";

drop function if exists public.attendance_guard_insert();
drop function if exists public.attendance_guard_update();
drop function if exists public.leave_request_guard_insert();
drop function if exists public.leave_request_guard_update();
drop function if exists public.leave_request_pending_balance();
drop function if exists public.claim_guard_insert();
drop function if exists public.claim_guard_update();
drop function if exists public.ot_guard_insert();
drop function if exists public.notification_guard_update();

-- ── Drop new policies ────────────────────────────────────────────────────────
do $$
declare r record;
begin
  for r in select tablename, policyname from pg_policies
           where schemaname = 'public' and policyname like 'emp_%'
  loop
    execute format('drop policy %I on public.%I', r.policyname, r.tablename);
  end loop;
end $$;

drop function if exists public.app_user_id();
drop function if exists public.app_company_id();
drop function if exists public.is_app_request();

-- ── Restore original policies ────────────────────────────────────────────────
create policy authenticated_all on public."ClaimRequests"  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy authenticated_all on public."Notifications"  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy authenticated_all on public."OtRequests"     for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy authenticated_all on public."PayrollRecords" for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy authenticated_all on public.attendance       for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy authenticated_all on public.companies        for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy authenticated_all on public.employees        for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "employee can read own row" on public.employees for select using (user_id = auth.uid());
create policy authenticated_all on public.leave_balances   for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy allow_all_leave_balances on public.leave_balances for all using (true) with check (true);
create policy authenticated_all on public.leave_policies   for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy authenticated_all on public.leave_requests   for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy allow_all_leave_requests on public.leave_requests for all using (true) with check (true);
create policy authenticated_all on public.policy_chunks    for select using (auth.role() = 'authenticated');
create policy "Allow read access to policy_chunks for anon and authenticated" on public.policy_chunks for select to anon, authenticated using (true);
create policy authenticated_all on public.users            for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

commit;
