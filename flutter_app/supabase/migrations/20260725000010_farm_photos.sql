create table public.farm_photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  farm_id uuid not null references public.farm_profiles(id) on delete cascade,
  storage_path text not null check (char_length(storage_path) between 1 and 500),
  taken_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index farm_photos_farm_id_taken_at_idx
  on public.farm_photos(farm_id, taken_at desc);

create index farm_photos_user_id_idx on public.farm_photos(user_id);

alter table public.farm_photos enable row level security;

-- Ownership is checked two ways on insert: the row's user_id must equal the
-- caller, AND the farm_id must belong to that same caller. Otherwise a client
-- could attach a photo to someone else's farm by lying about farm_id.

create policy "farmers read their own farm photos"
  on public.farm_photos for select
  using (auth.uid() = user_id);

create policy "farmers insert photos for their own farms"
  on public.farm_photos for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.farm_profiles f
      where f.id = farm_photos.farm_id and f.user_id = auth.uid()
    )
  );

create policy "farmers update their own farm photos"
  on public.farm_photos for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "farmers delete their own farm photos"
  on public.farm_photos for delete
  using (auth.uid() = user_id);

