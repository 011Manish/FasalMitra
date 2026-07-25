-- Agronomic lookup. Placeholder values until we get real numbers from an
-- agronomist. Kept in a table (not hard-coded in the function) so it can
-- be tweaked without a code deploy.

create table public.crop_rules (
  crop_type public.crop_type primary key,
  growth_days int not null check (growth_days > 0),
  harvest_window_days int not null check (harvest_window_days > 0),
  watering_interval_days int not null check (watering_interval_days > 0),
  watering_until_day int not null check (watering_until_day > 0),
  fertilizer_schedule jsonb not null
);

alter table public.crop_rules enable row level security;

create policy "crop rules are readable by any signed-in user"
  on public.crop_rules for select
  to authenticated
  using (true);

-- Writes go through the service role only (migrations / admin scripts).
-- No insert/update/delete policy is defined for regular users on purpose.

insert into public.crop_rules (crop_type, growth_days, harvest_window_days,
                               watering_interval_days, watering_until_day,
                               fertilizer_schedule)
values
  ('rice',  120, 14, 3,  100, '[
    {"name": "Basal N-P-K",                          "day_offset": 0},
    {"name": "Top dressing urea (tillering)",        "day_offset": 25},
    {"name": "Top dressing urea (panicle initiation)","day_offset": 55}
  ]'::jsonb),
  ('maize', 110, 10, 5,  95, '[
    {"name": "Basal N-P-K",                          "day_offset": 0},
    {"name": "Side dressing urea (knee-high)",       "day_offset": 30},
    {"name": "Top dressing urea (tasseling)",        "day_offset": 55}
  ]'::jsonb),
  ('wheat', 135, 14, 10, 110, '[
    {"name": "Basal N-P-K",                          "day_offset": 0},
    {"name": "Top dressing urea (tillering)",        "day_offset": 30},
    {"name": "Top dressing urea (jointing)",         "day_offset": 60}
  ]'::jsonb);
