-- Rules for the new crops. PLACEHOLDER values: have an agronomist or the
-- local agriculture office verify them before real use.

insert into public.crop_rules (crop_type, growth_days, harvest_window_days,
  watering_interval_days, watering_until_day, fertilizer_schedule) values
('potato', 100, 10, 7, 80, '[
  {"name": "Basal N-P-K", "day_offset": 0},
  {"name": "Top dressing urea (earthing up)", "day_offset": 30}]'::jsonb),
('tomato', 110, 30, 4, 100, '[
  {"name": "Basal N-P-K", "day_offset": 0},
  {"name": "Top dressing (flowering)", "day_offset": 35},
  {"name": "Top dressing (fruit set)", "day_offset": 60}]'::jsonb),
('cauliflower', 90, 14, 5, 80, '[
  {"name": "Basal N-P-K", "day_offset": 0},
  {"name": "Top dressing urea", "day_offset": 25}]'::jsonb),
('onion', 130, 14, 7, 110, '[
  {"name": "Basal N-P-K", "day_offset": 0},
  {"name": "Top dressing urea", "day_offset": 30},
  {"name": "Top dressing urea", "day_offset": 60}]'::jsonb),
('millet', 110, 10, 10, 90, '[
  {"name": "Basal N-P-K", "day_offset": 0},
  {"name": "Top dressing urea", "day_offset": 30}]'::jsonb),
('lentil', 120, 10, 14, 90, '[
  {"name": "Basal phosphate", "day_offset": 0}]'::jsonb)
on conflict (crop_type) do nothing;