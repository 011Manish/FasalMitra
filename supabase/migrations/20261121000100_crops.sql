-- Crop guide data: browsable crop info used by the Crop Guide screen.
-- Placeholder content (is_verified = false) until an agronomist checks it.
-- Record only: this table already exists in production.
-- Nepali names are written as \u escapes (E'' strings) to keep the file ASCII.

create table public.crops (
  id uuid primary key default gen_random_uuid(),
  crop_type text not null unique check (char_length(crop_type) between 1 and 40),
  name text not null check (char_length(name) between 1 and 120),
  name_ne text,
  seasons text[] not null default '{}'
    check (seasons <@ array['monsoon', 'winter', 'spring']),
  duration_days int not null check (duration_days > 0),
  water_need text not null default 'medium'
    check (water_need in ('low', 'medium', 'high')),
  suitable_soils text[] not null default '{}'
    check (suitable_soils <@ array['sandy', 'loamy', 'clay', 'silty', 'peaty', 'chalky']),
  growing_steps jsonb not null default '[]'::jsonb,
  notes text,
  is_verified boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.crops enable row level security;

create policy "crops readable by signed-in users"
  on public.crops for select to authenticated
  using (is_active or public.is_admin());

create policy "admins insert crops"
  on public.crops for insert to authenticated
  with check (public.is_admin());

create policy "admins update crops"
  on public.crops for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "admins delete crops"
  on public.crops for delete to authenticated
  using (public.is_admin());

create trigger crops_touch_updated_at
  before update on public.crops
  for each row execute function public.touch_updated_at();

insert into public.crops
  (crop_type, name, name_ne, seasons, duration_days, water_need, suitable_soils, growing_steps) values
('rice', 'Rice', E'\u091a\u093e\u092e\u0932', array['monsoon'], 120, 'high', array['loamy','clay','silty'],
 '["Prepare a nursery and sow seed","Plough and puddle the field","Transplant seedlings at 20 to 25 days","Keep shallow standing water until grain filling","Drain the field and harvest when grains turn golden"]'::jsonb),
('maize', 'Maize', E'\u092e\u0915\u0948', array['spring','monsoon'], 110, 'medium', array['loamy','sandy','silty'],
 '["Plough and level the field","Sow seed in rows with spacing","Weed and thin at 2 to 3 weeks","Side-dress with nitrogen fertilizer","Harvest when husks dry and kernels harden"]'::jsonb),
('wheat', 'Wheat', E'\u0917\u0939\u0941\u0901', array['winter'], 135, 'medium', array['loamy','clay','silty'],
 '["Prepare a fine seedbed","Sow seed in rows","Irrigate at crown root and tillering stages","Top-dress with nitrogen","Harvest when grains are hard and straw is golden"]'::jsonb),
('potato', 'Potato', E'\u0906\u0932\u0941', array['winter'], 100, 'medium', array['sandy','loamy'],
 '["Prepare loose, well-drained beds","Plant healthy seed tubers","Earth up soil around plants at 4 weeks","Irrigate lightly and regularly","Harvest after the vines dry"]'::jsonb),
('tomato', 'Tomato', E'\u0917\u094b\u0932\u092d\u0947\u0902\u0921\u093e', array['winter','spring'], 110, 'medium', array['loamy','sandy'],
 '["Raise seedlings in a nursery","Transplant at 4 to 5 weeks","Stake plants and prune side shoots","Water regularly, avoid wetting leaves","Pick fruits as they colour"]'::jsonb),
('cauliflower', 'Cauliflower', E'\u0915\u093e\u0909\u0932\u0940', array['winter'], 90, 'medium', array['loamy','silty'],
 '["Raise seedlings in a nursery","Transplant into rich, well-drained soil","Irrigate regularly and weed","Top-dress with nitrogen","Harvest while the curd is firm and white"]'::jsonb),
('onion', 'Onion', E'\u092a\u094d\u092f\u093e\u091c', array['winter'], 130, 'medium', array['loamy','sandy'],
 '["Raise seedlings in a nursery","Transplant at 6 to 8 weeks","Keep weeds down and irrigate lightly","Stop watering as tops fall over","Harvest, cure in shade and store dry"]'::jsonb),
('millet', 'Millet', E'\u0915\u094b\u0926\u094b', array['monsoon'], 110, 'low', array['sandy','loamy'],
 '["Prepare a rough seedbed","Broadcast or line-sow seed","Thin and weed at 3 weeks","Needs little extra water","Harvest when heads turn brown"]'::jsonb),
('lentil', 'Lentil', E'\u092e\u0938\u0941\u0930\u094b', array['winter'], 120, 'low', array['loamy','sandy'],
 '["Prepare a fine seedbed","Sow seed in rows after the rains","Weed early","Usually needs little or no irrigation","Harvest when pods turn brown"]'::jsonb);