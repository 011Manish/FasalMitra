alter table public.plant_health_scans
  alter column farm_id drop not null;

drop policy if exists "farmers insert plant scans for their own farms"
  on public.plant_health_scans;

create policy "users insert own plant scans"
  on public.plant_health_scans
  for insert to authenticated
  with check (
    auth.uid() = user_id
    and (
      farm_id is null
      or exists (
        select 1 from public.farm_profiles f
        where f.id = farm_id and f.user_id = auth.uid()
      )
    )
  );