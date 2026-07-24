create type public.schedule_kind as enum ('watering', 'fertilizer', 'harvest');
create type public.schedule_status as enum ('pending', 'done', 'skipped');

create table public.schedule_items (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references public.farm_profiles(id) on delete cascade,
  kind public.schedule_kind not null,
  title text not null check (char_length(title) between 1 and 200),
  due_date date not null,
  status public.schedule_status not null default 'pending',
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index schedule_items_farm_id_due_date_idx
  on public.schedule_items(farm_id, due_date);

alter table public.schedule_items enable row level security;

-- RLS chains through farm_profiles.user_id — a schedule item belongs to
-- whoever owns its farm. Every policy re-checks ownership so a malicious
-- farm_id in the request body can't be used to leak or clobber someone
-- else's rows.

create policy "farmers read their own schedule items"
  on public.schedule_items for select
  using (
    exists (
      select 1 from public.farm_profiles f
      where f.id = schedule_items.farm_id and f.user_id = auth.uid()
    )
  );

create policy "farmers insert schedule items for their own farms"
  on public.schedule_items for insert
  with check (
    exists (
      select 1 from public.farm_profiles f
      where f.id = schedule_items.farm_id and f.user_id = auth.uid()
    )
  );

create policy "farmers update their own schedule items"
  on public.schedule_items for update
  using (
    exists (
      select 1 from public.farm_profiles f
      where f.id = schedule_items.farm_id and f.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.farm_profiles f
      where f.id = schedule_items.farm_id and f.user_id = auth.uid()
    )
  );

create policy "farmers delete their own schedule items"
  on public.schedule_items for delete
  using (
    exists (
      select 1 from public.farm_profiles f
      where f.id = schedule_items.farm_id and f.user_id = auth.uid()
    )
  );

create trigger schedule_items_touch_updated_at
  before update on public.schedule_items
  for each row execute function public.touch_updated_at();
