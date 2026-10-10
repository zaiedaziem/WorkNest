-- Secure employee access from the mobile app
--
-- Before: every table had an "authenticated_all" policy (and leave_requests /
-- leave_balances allowed even anonymous access), so any signed-in employee could
-- read or change every other employee's records, payroll and company settings.
--
-- After:
--   * Employees can only read their own records, and their own company's settings
--     and leave policies.
--   * Writes are limited to what the app actually does (clock in/out, apply/cancel
--     leave, submit/cancel claims, submit OT, mark notifications read), and
--     triggers enforce the business rules on the server: clock-in time, date,
--     late status and office radius; leave day counts, balance check and pending
--     days; new requests always start as "pending".
--
-- The web portal connects as the "postgres" role (bypasses RLS) and the chat Edge
-- Function uses the service role; the guards below only apply to requests from
-- signed-in app users, so HR's actions in the web portal are unaffected.
--
-- Rollback: supabase/rollbacks/20261010000000_rollback_secure_employee_access.sql

begin;

-- ── Helpers ──────────────────────────────────────────────────────────────────

-- True only for requests made by a signed-in app user (not HR's web portal,
-- which connects as postgres, and not the service role).
create or replace function public.is_app_request() returns boolean
language sql stable as $$
  select coalesce(auth.role(), '') = 'authenticated'
$$;

-- The public.users row of the signed-in app user (matched by login email).
create or replace function public.app_user_id() returns uuid
language sql stable security definer set search_path = public as $$
  select id from users
  where lower(email) = lower(auth.jwt() ->> 'email') and is_active
  limit 1
$$;

create or replace function public.app_company_id() returns uuid
language sql stable security definer set search_path = public as $$
  select company_id from users
  where lower(email) = lower(auth.jwt() ->> 'email') and is_active
  limit 1
$$;

-- ── Drop the old open policies ───────────────────────────────────────────────
drop policy if exists authenticated_all on public."ClaimRequests";
drop policy if exists authenticated_all on public."Notifications";
drop policy if exists authenticated_all on public."OtRequests";
drop policy if exists authenticated_all on public."PayrollRecords";
drop policy if exists authenticated_all on public.attendance;
drop policy if exists authenticated_all on public.companies;
drop policy if exists authenticated_all on public.employees;
drop policy if exists "employee can read own row" on public.employees;
drop policy if exists authenticated_all on public.leave_balances;
drop policy if exists allow_all_leave_balances on public.leave_balances;
drop policy if exists authenticated_all on public.leave_policies;
drop policy if exists authenticated_all on public.leave_requests;
drop policy if exists allow_all_leave_requests on public.leave_requests;
drop policy if exists authenticated_all on public.policy_chunks;
drop policy if exists "Allow read access to policy_chunks for anon and authenticated" on public.policy_chunks;
drop policy if exists authenticated_all on public.users;

-- ── New policies: own records only ───────────────────────────────────────────
create policy emp_select_own_user      on public.users          for select to authenticated using (id = public.app_user_id());
create policy emp_select_own_company   on public.companies      for select to authenticated using (id = public.app_company_id());
create policy emp_select_own_employee  on public.employees      for select to authenticated using (user_id = public.app_user_id());
create policy emp_select_company_leave_policies on public.leave_policies for select to authenticated using (company_id = public.app_company_id());
create policy emp_select_own_leave_balances     on public.leave_balances for select to authenticated using (employee_id = public.app_user_id());
create policy emp_select_policy_chunks on public.policy_chunks  for select to authenticated using (true);

create policy emp_select_own_attendance on public.attendance for select to authenticated using (employee_id = public.app_user_id());
create policy emp_insert_own_attendance on public.attendance for insert to authenticated with check (employee_id = public.app_user_id());
create policy emp_update_own_attendance on public.attendance for update to authenticated using (employee_id = public.app_user_id()) with check (employee_id = public.app_user_id());

create policy emp_select_own_leave_requests on public.leave_requests for select to authenticated using (employee_id = public.app_user_id());
create policy emp_insert_own_leave_requests on public.leave_requests for insert to authenticated with check (employee_id = public.app_user_id());
create policy emp_update_own_leave_requests on public.leave_requests for update to authenticated using (employee_id = public.app_user_id()) with check (employee_id = public.app_user_id());

create policy emp_select_own_claims on public."ClaimRequests" for select to authenticated using ("EmployeeId" = public.app_user_id());
create policy emp_insert_own_claims on public."ClaimRequests" for insert to authenticated with check ("EmployeeId" = public.app_user_id());
create policy emp_update_own_claims on public."ClaimRequests" for update to authenticated using ("EmployeeId" = public.app_user_id()) with check ("EmployeeId" = public.app_user_id());

create policy emp_select_own_ot on public."OtRequests" for select to authenticated using ("EmployeeId" = public.app_user_id());
create policy emp_insert_own_ot on public."OtRequests" for insert to authenticated with check ("EmployeeId" = public.app_user_id());

create policy emp_select_own_payroll on public."PayrollRecords" for select to authenticated using ("EmployeeId" = public.app_user_id());

create policy emp_select_own_notifications on public."Notifications" for select to authenticated using ("UserId" = public.app_user_id());
create policy emp_update_own_notifications on public."Notifications" for update to authenticated using ("UserId" = public.app_user_id()) with check ("UserId" = public.app_user_id());
create policy emp_delete_own_notifications on public."Notifications" for delete to authenticated using ("UserId" = public.app_user_id());

-- ── Attendance: server decides time, date, late status and office radius ─────
create or replace function public.attendance_guard_insert() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  c companies%rowtype;
  local_now timestamp := now() at time zone 'Asia/Kuala_Lumpur';
  dist double precision;
begin
  if not public.is_app_request() then return new; end if;

  select co.* into c from companies co join users u on u.company_id = co.id where u.id = new.employee_id;
  if not found then raise exception 'Company not found.'; end if;
  if new.type not in ('office', 'wfh') then raise exception 'Invalid attendance type.'; end if;

  -- Never trust the phone's clock
  new.date       := local_now::date;
  new.clock_in   := now();
  new.clock_out  := null;
  new.created_at := now();
  -- Same rule as the web portal: late if more than 5 minutes after work start
  new.status := case when local_now::time > c.work_start_time + interval '5 minutes'
                     then 'late' else 'present' end;

  if new.type = 'office' and c.location_enabled
     and c.office_lat is not null and c.office_lng is not null then
    if new.clock_in_lat is null or new.clock_in_lng is null then
      raise exception 'Location is required for In Office clock in.';
    end if;
    -- Haversine distance in metres
    dist := 2 * 6371000 * asin(sqrt(
              power(sin(radians(new.clock_in_lat - c.office_lat) / 2), 2) +
              cos(radians(c.office_lat)) * cos(radians(new.clock_in_lat)) *
              power(sin(radians(new.clock_in_lng - c.office_lng) / 2), 2)));
    if dist > c.office_radius then
      raise exception 'You are %m away from the office. Must be within %m.', round(dist), c.office_radius;
    end if;
  end if;

  return new;
end $$;

-- Employees may only clock out (once); the server sets the time
create or replace function public.attendance_guard_update() returns trigger
language plpgsql as $$
declare r public.attendance;
begin
  if not public.is_app_request() then return new; end if;
  if old.clock_out is not null then raise exception 'You have already clocked out today.'; end if;
  r := old;
  r.clock_out := now();
  return r;
end $$;

create trigger trg_attendance_guard_insert before insert on public.attendance
  for each row execute function public.attendance_guard_insert();
create trigger trg_attendance_guard_update before update on public.attendance
  for each row execute function public.attendance_guard_update();

-- ── Leave requests: recount days, check balance, start as pending ────────────
create or replace function public.leave_request_guard_insert() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  b leave_balances%rowtype;
  remaining numeric;
begin
  if not public.is_app_request() then return new; end if;

  if not exists (select 1 from leave_policies p
                 where p.id = new.leave_policy_id and p.company_id = public.app_company_id() and p.is_active) then
    raise exception 'Invalid leave type.';
  end if;
  if new.end_date < new.start_date then raise exception 'End date must be on or after the start date.'; end if;

  -- Same rule as the app: weekdays only; a half day is 0.5 on a single date
  if new.is_half_day then
    if new.end_date <> new.start_date then raise exception 'A half-day leave must be a single date.'; end if;
    new.total_days := 0.5;
  else
    select count(*) into new.total_days
    from generate_series(new.start_date, new.end_date, interval '1 day') d
    where extract(isodow from d) < 6;
  end if;
  if new.total_days <= 0 then raise exception 'The selected dates contain no working days.'; end if;

  select * into b from leave_balances
  where employee_id = new.employee_id and leave_policy_id = new.leave_policy_id
    and year = extract(year from new.start_date)::int;
  if found then
    remaining := b.total_days - b.used_days - b.pending_days;
    if new.total_days > remaining then
      raise exception 'Insufficient balance. You have % day(s) remaining.', remaining;
    end if;
  end if;

  new.company_id  := public.app_company_id();
  new.status      := 'pending';
  new.hr_remarks  := null;
  new.approved_by := null;
  new.approved_at := null;
  new.created_at  := now();
  return new;
end $$;

-- Employees may only cancel their own pending request
create or replace function public.leave_request_guard_update() returns trigger
language plpgsql as $$
declare r public.leave_requests;
begin
  if not public.is_app_request() then return new; end if;
  if old.status <> 'pending' or new.status <> 'cancelled' then
    raise exception 'Only pending requests can be cancelled.';
  end if;
  r := old;
  r.status := 'cancelled';
  return r;
end $$;

-- Keep pending_days in step with the employee's own apply / cancel actions
-- (HR approve/reject in the web portal updates balances itself)
create or replace function public.leave_request_pending_balance() returns trigger
language plpgsql security definer set search_path = public as $$
declare delta numeric;
begin
  if not public.is_app_request() then return null; end if;
  if tg_op = 'INSERT' then
    delta := new.total_days;
  elsif old.status = 'pending' and new.status = 'cancelled' then
    delta := -new.total_days;
  else
    return null;
  end if;
  update leave_balances
     set pending_days = greatest(pending_days + delta, 0)
   where employee_id = new.employee_id and leave_policy_id = new.leave_policy_id
     and year = extract(year from new.start_date)::int;
  return null;
end $$;

create trigger trg_leave_request_guard_insert before insert on public.leave_requests
  for each row execute function public.leave_request_guard_insert();
create trigger trg_leave_request_guard_update before update on public.leave_requests
  for each row execute function public.leave_request_guard_update();
create trigger trg_leave_request_pending_balance after insert or update on public.leave_requests
  for each row execute function public.leave_request_pending_balance();

-- ── Claims: start as pending; employees may only cancel a pending claim ──────
create or replace function public.claim_guard_insert() returns trigger
language plpgsql as $$
begin
  if not public.is_app_request() then return new; end if;
  new."CompanyId"       := public.app_company_id();
  new."Status"          := 'pending';
  new."RejectionReason" := null;
  new."ReviewedBy"      := null;
  new."ReviewedAt"      := null;
  new."ApprovedAmount"  := null;
  new."CreatedAt"       := now();
  return new;
end $$;

create or replace function public.claim_guard_update() returns trigger
language plpgsql as $$
declare r public."ClaimRequests";
begin
  if not public.is_app_request() then return new; end if;
  if old."Status" <> 'pending' or new."Status" <> 'cancelled' then
    raise exception 'Only pending claims can be cancelled.';
  end if;
  r := old;
  r."Status" := 'cancelled';
  return r;
end $$;

create trigger trg_claim_guard_insert before insert on public."ClaimRequests"
  for each row execute function public.claim_guard_insert();
create trigger trg_claim_guard_update before update on public."ClaimRequests"
  for each row execute function public.claim_guard_update();

-- ── OT requests: start as pending ────────────────────────────────────────────
create or replace function public.ot_guard_insert() returns trigger
language plpgsql as $$
begin
  if not public.is_app_request() then return new; end if;
  new."CompanyId"    := public.app_company_id();
  new."Status"       := 'pending';
  new."HrRemarks"    := null;
  new."ApprovedById" := null;
  new."CreatedAt"    := now();
  return new;
end $$;

create trigger trg_ot_guard_insert before insert on public."OtRequests"
  for each row execute function public.ot_guard_insert();

-- ── Notifications: employees may only mark them read ─────────────────────────
create or replace function public.notification_guard_update() returns trigger
language plpgsql as $$
declare r public."Notifications";
begin
  if not public.is_app_request() then return new; end if;
  r := old;
  r."IsRead" := new."IsRead";
  return r;
end $$;

create trigger trg_notification_guard_update before update on public."Notifications"
  for each row execute function public.notification_guard_update();

commit;
