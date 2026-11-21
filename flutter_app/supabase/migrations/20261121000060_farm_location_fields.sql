-- Farm location fields (brief feature C): state or province, district, municipality.
-- Nullable so existing farms are unaffected. Existing RLS policies still apply.

alter table public.farm_profiles
  add column if not exists state_province text,
  add column if not exists district text,
  add column if not exists municipality text;