alter table public.crop_price_history
  add column market_name text,
  add column is_demo boolean not null default true,
  add column updated_at timestamptz not null default now();

update public.crop_price_history
set is_demo = true,
    market_name = 'Kalimati (sample data)'
where source = 'kalimati';