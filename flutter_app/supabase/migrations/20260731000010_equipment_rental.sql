create table public.rental_equipment (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null
    check (category in ('Tractor', 'Harvester', 'Sprayer', 'Irrigation')),
  daily_rate numeric(10, 2) not null check (daily_rate >= 0),
  description text not null default '',
  photo_url text,
  provider_name text,
  provider_phone text,
  provider_address text,
  place_id text,
  created_at timestamptz not null default now()
);

alter table public.rental_equipment enable row level security;

create policy "rental equipment is readable by any signed-in user"
  on public.rental_equipment for select
  to authenticated
  using (true);

-- Writes go through the service role only (migrations / admin scripts).
-- No insert/update/delete policy is defined for regular users on purpose.

create table public.equipment_bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  equipment_id uuid not null references public.rental_equipment(id),
  start_date date not null,
  end_date date not null,
  status text not null default 'pending'
    check (status in ('pending', 'confirmed', 'active', 'completed', 'cancelled')),
  total_amount numeric(10, 2) not null check (total_amount >= 0),
  place_id text,
  place_name text,
  place_address text,
  requested_at timestamptz not null default now(),
  check (end_date >= start_date)
);

create index equipment_bookings_user_idx
  on public.equipment_bookings(user_id, requested_at desc);

create index equipment_bookings_equipment_idx
  on public.equipment_bookings(equipment_id, start_date);

alter table public.equipment_bookings enable row level security;

create policy "farmers read their own bookings"
  on public.equipment_bookings for select
  using (auth.uid() = user_id);

create policy "farmers create their own bookings"
  on public.equipment_bookings for insert
  with check (auth.uid() = user_id);

create policy "farmers update their own bookings"
  on public.equipment_bookings for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "farmers delete their own bookings"
  on public.equipment_bookings for delete
  using (auth.uid() = user_id);

-- Availability check needs to show busy dates from OTHER users' bookings
-- too, which owner-scoped RLS above correctly blocks. Rather than adding
-- a broad SELECT policy that would expose every user's full booking row,
-- expose only the 3 harmless columns needed via a security-definer function.
create or replace function public.equipment_booking_availability(p_equipment_id uuid)
returns table (start_date date, end_date date, status text)
language sql
security definer
set search_path = public
as $$
  select start_date, end_date, status
  from public.equipment_bookings
  where equipment_id = p_equipment_id
    and status <> 'cancelled';
$$;

grant execute on function public.equipment_booking_availability(uuid) to authenticated;