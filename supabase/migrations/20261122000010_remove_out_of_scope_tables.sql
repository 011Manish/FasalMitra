-- Remove tables that the client brief does not ask for: expert consultations and
-- IoT (both excluded in section 6), finance, equipment rental, and the old
-- products table (replaced by catalog_products). They held only test data.
-- Runs as one transaction: if any step fails, nothing is changed.

begin;

-- The equipment rental feature's own availability function (any signature).
do $$
declare
  f record;
begin
  for f in
    select oid::regprocedure as sig from pg_proc
    where pronamespace = 'public'::regnamespace
      and proname = 'equipment_booking_availability'
  loop
    execute format('drop function %s', f.sig);
  end loop;
end $$;

-- Abort if any other function in public still uses these tables, so nothing the app
-- calls is left broken. The message lists the function names.
do $$
declare
  offenders text;
begin
  select string_agg(proname, ', ') into offenders
  from pg_proc
  where pronamespace = 'public'::regnamespace
    and prosrc ~* '(consultation_appointments|consultation_messages|experts|farm_devices|sensor_readings|finance_info|farm_income_entries|equipment_bookings|rental_equipment|\mproducts\M)';
  if offenders is not null then
    raise exception 'Functions still reference these tables: %', offenders;
  end if;
end $$;

-- Children first. No CASCADE, so a hidden dependency makes this fail instead.
drop table if exists public.consultation_messages;
drop table if exists public.consultation_appointments;
drop table if exists public.experts;
drop table if exists public.sensor_readings;
drop table if exists public.farm_devices;
drop table if exists public.farm_income_entries;
drop table if exists public.finance_info;
drop table if exists public.equipment_bookings;
drop table if exists public.rental_equipment;
drop table if exists public.products;

commit;