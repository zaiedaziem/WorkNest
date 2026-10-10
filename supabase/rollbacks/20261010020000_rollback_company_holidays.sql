-- ROLLBACK for 20261010020000_company_holidays.sql
begin;

drop function if exists public.company_holidays(date, date);

delete from public.public_holidays where company_id is not null;

drop policy if exists emp_select_public_holidays on public.public_holidays;
create policy emp_select_public_holidays on public.public_holidays
  for select to authenticated using (true);

drop index if exists public.public_holidays_date_name_company_key;
alter table public.public_holidays drop constraint if exists public_holidays_pkey;
alter table public.public_holidays drop column if exists company_id;
alter table public.public_holidays drop column if exists id;
alter table public.public_holidays add primary key (date, name);

commit;
