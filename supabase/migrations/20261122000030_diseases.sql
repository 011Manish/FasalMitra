-- Record only: already applied to production
-- Table public.diseases. No earlier migration file creates it.
-- Recorded exactly as production has it, nothing changed. It is not in the
-- client brief. Its policy lets logged-out visitors read every row; that is
-- recorded as is and is a separate decision for later.
-- Grants are not recorded (TO CONFIRM).
-- Safe to run again.

create table if not exists public.diseases (
  id uuid primary key default gen_random_uuid(),
  crop_name text not null,
  disease_name text not null,
  symptoms text,
  causes text,
  treatment text,
  prevention text,
  image_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.diseases enable row level security;

drop policy if exists "Diseases are publicly readable" on public.diseases;
create policy "Diseases are publicly readable"
  on public.diseases for select
  to public
  using (true);