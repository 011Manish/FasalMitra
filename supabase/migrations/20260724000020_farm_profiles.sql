create type public.crop_type as enum ('rice', 'maize', 'wheat');
create type public.soil_type as enum ('sandy', 'loamy', 'clay', 'silty', 'peaty', 'chalky');
create type public.irrigation_system as enum ('rainfed', 'drip', 'sprinkler', 'flood', 'canal');

create table public.farm_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 120),
  crop_type public.crop_type not null,
  land_size_hectares numeric(10, 3) not null check (land_size_hectares > 0 and land_size_hectares <= 10000),
  plantation_date date not null check (plantation_date <= current_date),
  soil_type public.soil_type not null,
  irrigation_system public.irrigation_system not null,
  location_label text check (location_label is null or char_length(location_label) <= 200),
  latitude numeric(9, 6) check (latitude is null or (latitude between -90 and 90)),
  longitude numeric(9, 6) check (longitude is null or (longitude between -180 and 180)),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index farm_profiles_user_id_idx on public.farm_profiles(user_id);

alter table public.farm_profiles enable row level security;

create policy "farmers read their own farm profiles"
  on public.farm_profiles for select
  using (auth.uid() = user_id);

create policy "farmers insert their own farm profiles"
  on public.farm_profiles for insert
  with check (auth.uid() = user_id);

create policy "farmers update their own farm profiles"
  on public.farm_profiles for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "farmers delete their own farm profiles"
  on public.farm_profiles for delete
  using (auth.uid() = user_id);

create trigger farm_profiles_touch_updated_at
  before update on public.farm_profiles
  for each row execute function public.touch_updated_at();
