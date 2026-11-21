-- Store the land size as the farmer entered it, plus its unit.
-- land_size_hectares stays as the converted value the rest of the app uses.

alter table public.farm_profiles
  add column land_size_value numeric(12, 3)
    check (land_size_value is null or land_size_value > 0),
  add column land_unit text not null default 'hectare'
    check (land_unit in ('hectare', 'acre', 'ropani', 'kattha', 'bigha'));

update public.farm_profiles
set land_size_value = land_size_hectares
where land_size_value is null;