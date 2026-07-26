create table public.plant_health_scans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  farm_id uuid not null references public.farm_profiles(id) on delete cascade,
  photo_storage_path text not null check (char_length(photo_storage_path) between 1 and 500),
  analysis jsonb not null,
  confidence_level text not null check (confidence_level in ('high', 'medium', 'low')),
  created_at timestamptz not null default now()
);

create index plant_health_scans_farm_id_created_at_idx
  on public.plant_health_scans(farm_id, created_at desc);

create index plant_health_scans_user_id_idx on public.plant_health_scans(user_id);

alter table public.plant_health_scans enable row level security;

-- Same double-check as farm_photos: user_id must match the caller, AND
-- farm_id must belong to that same caller, so a client can't attach a scan
-- to a farm it doesn't own by lying about farm_id.

create policy "farmers read their own plant scans"
  on public.plant_health_scans for select
  using (auth.uid() = user_id);

create policy "farmers insert plant scans for their own farms"
  on public.plant_health_scans for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.farm_profiles f
      where f.id = plant_health_scans.farm_id and f.user_id = auth.uid()
    )
  );

create policy "farmers update their own plant scans"
  on public.plant_health_scans for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "farmers delete their own plant scans"
  on public.plant_health_scans for delete
  using (auth.uid() = user_id);