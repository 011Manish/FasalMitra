create table public.finance_info (
  id uuid primary key default gen_random_uuid(),
  category text not null check (category in ('insurance', 'loan', 'subsidy')),
  title text not null,
  body text not null,
  created_at timestamptz not null default now()
);

create index finance_info_category_idx on public.finance_info(category);

alter table public.finance_info enable row level security;

create policy "finance info is readable by any signed-in user"
  on public.finance_info for select
  to authenticated
  using (true);

-- Writes go through the service role only (migrations / admin scripts).
-- No insert/update/delete policy is defined for regular users on purpose.

create table public.farm_income_entries (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references public.farm_profiles(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  description text not null,
  amount numeric(12, 2) not null,
  entry_date date not null,
  created_at timestamptz not null default now()
);

create index farm_income_entries_farm_date_idx
  on public.farm_income_entries(farm_id, entry_date desc);

alter table public.farm_income_entries enable row level security;

create policy "farmers read their own income entries"
  on public.farm_income_entries for select
  using (auth.uid() = user_id);

create policy "farmers insert income entries for their own farms"
  on public.farm_income_entries for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.farm_profiles f
      where f.id = farm_income_entries.farm_id and f.user_id = auth.uid()
    )
  );

create policy "farmers update their own income entries"
  on public.farm_income_entries for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "farmers delete their own income entries"
  on public.farm_income_entries for delete
  using (auth.uid() = user_id);