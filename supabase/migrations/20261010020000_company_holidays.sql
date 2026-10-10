-- Company-aware holidays
--
-- Requires companies.state (added by the web portal's EF migration
-- 20261010095359_AddCompanyState).
--
-- * public_holidays.company_id: null = public holiday, set = a day off that only
--   applies to that company (added by HR in the web portal's Holidays page).
-- * company_holidays(from, to): the holidays that apply to the signed-in
--   employee's company — nationwide + its state's + its own days off. The web
--   portal's HolidayService applies the same rule.
--
-- Rollback: supabase/rollbacks/20261010020000_rollback_company_holidays.sql

begin;

alter table public.public_holidays add column if not exists id uuid not null default gen_random_uuid();
alter table public.public_holidays add column if not exists company_id uuid
  references public.companies(id) on delete cascade;

-- (date, name) is no longer unique on its own: two companies may add the same day off
alter table public.public_holidays drop constraint if exists public_holidays_pkey;
alter table public.public_holidays add primary key (id);
create unique index if not exists public_holidays_date_name_company_key
  on public.public_holidays (date, name, coalesce(company_id, '00000000-0000-0000-0000-000000000000'::uuid));

-- Employees see public holidays and their own company's days off only
drop policy if exists emp_select_public_holidays on public.public_holidays;
create policy emp_select_public_holidays on public.public_holidays
  for select to authenticated
  using (company_id is null or company_id = public.app_company_id());

create or replace function public.company_holidays(p_from date, p_to date)
returns table (date date, name text)
language sql stable set search_path = public as $$
  select h.date, string_agg(h.name, ' / ' order by h.name)
  from public_holidays h
  left join companies c on c.id = public.app_company_id()
  where h.date between p_from and p_to
    and (
      h.company_id = public.app_company_id()
      or (h.company_id is null and (
            h.regions is null
            or (c.state is not null and c.state = any (string_to_array(h.regions, ', ')))
          ))
    )
  group by h.date
  order by h.date
$$;

commit;
