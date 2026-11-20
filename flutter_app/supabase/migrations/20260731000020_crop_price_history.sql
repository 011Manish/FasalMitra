create table public.crop_price_history (
  id uuid primary key default gen_random_uuid(),
  crop_name text not null,
  source text not null check (source in ('kalimati', 'marketplace')),
  recorded_date date not null,
  avg_price numeric(10, 2) not null check (avg_price >= 0),
  min_price numeric(10, 2) not null check (min_price >= 0),
  max_price numeric(10, 2) not null check (max_price >= 0),
  unit text not null default 'per kg'
);

create index crop_price_history_crop_idx
  on public.crop_price_history(crop_name, recorded_date);

alter table public.crop_price_history enable row level security;

create policy "crop price history is readable by any signed-in user"
  on public.crop_price_history for select
  to authenticated
  using (true);

-- Writes go through the service role only (migrations / admin scripts,
-- and later, a Marketplace-triggered writer using source = 'marketplace').
-- No insert/update/delete policy is defined for regular users on purpose.

insert into public.crop_price_history (crop_name, source, recorded_date, avg_price, min_price, max_price) values
('Tomato', 'kalimati', '2026-06-05', 38.0, 34.0, 42.0),
('Tomato', 'kalimati', '2026-06-12', 36.5, 32.0, 41.0),
('Tomato', 'kalimati', '2026-06-19', 39.0, 35.0, 43.0),
('Tomato', 'kalimati', '2026-06-26', 41.0, 37.0, 45.0),
('Tomato', 'kalimati', '2026-07-03', 40.0, 36.0, 44.0),
('Tomato', 'kalimati', '2026-07-10', 42.5, 38.0, 47.0),
('Tomato', 'kalimati', '2026-07-17', 43.5, 39.0, 48.0),
('Tomato', 'kalimati', '2026-07-24', 44.5, 40.0, 50.0),
('Potato', 'kalimati', '2026-06-05', 42.0, 39.0, 45.0),
('Potato', 'kalimati', '2026-06-12', 43.0, 40.0, 46.0),
('Potato', 'kalimati', '2026-06-19', 43.5, 41.0, 46.0),
('Potato', 'kalimati', '2026-06-26', 44.0, 41.0, 47.0),
('Potato', 'kalimati', '2026-07-03', 44.8, 42.0, 47.0),
('Potato', 'kalimati', '2026-07-10', 45.2, 42.0, 48.0),
('Potato', 'kalimati', '2026-07-17', 46.0, 43.0, 48.0),
('Potato', 'kalimati', '2026-07-24', 46.5, 45.0, 48.0),
('Onion', 'kalimati', '2026-06-05', 62.0, 58.0, 66.0),
('Onion', 'kalimati', '2026-06-12', 60.0, 56.0, 64.0),
('Onion', 'kalimati', '2026-06-19', 58.5, 54.0, 62.0),
('Onion', 'kalimati', '2026-06-26', 59.0, 55.0, 63.0),
('Onion', 'kalimati', '2026-07-03', 57.5, 53.0, 61.0),
('Onion', 'kalimati', '2026-07-10', 56.0, 52.0, 60.0),
('Onion', 'kalimati', '2026-07-17', 56.5, 53.0, 60.0),
('Onion', 'kalimati', '2026-07-24', 55.8, 54.0, 57.0),
('Cauliflower', 'kalimati', '2026-06-05', 55.0, 48.0, 62.0),
('Cauliflower', 'kalimati', '2026-06-12', 50.0, 44.0, 56.0),
('Cauliflower', 'kalimati', '2026-06-19', 48.0, 42.0, 54.0),
('Cauliflower', 'kalimati', '2026-06-26', 45.0, 40.0, 50.0),
('Cauliflower', 'kalimati', '2026-07-03', 43.0, 38.0, 48.0),
('Cauliflower', 'kalimati', '2026-07-10', 40.0, 36.0, 44.0),
('Cauliflower', 'kalimati', '2026-07-17', 38.5, 34.0, 43.0),
('Cauliflower', 'kalimati', '2026-07-24', 37.0, 33.0, 41.0);