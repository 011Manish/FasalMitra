create table public.experts (
  id uuid primary key,
  name text not null,
  specialty text not null,
  bio text not null,
  photo_url text,
  created_at timestamptz not null default now()
);