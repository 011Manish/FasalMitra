-- Admin controls (brief section I): demo market prices, crop rules, listing
-- moderation and user review. Admin status always comes from public.is_admin().
-- Runs as one transaction: if any step fails, nothing is changed.

begin;

-- is_admin() is read inside policies on public.profiles. It must be SECURITY
-- DEFINER, otherwise those policies would recurse and break every profile query.
do $$
begin
  if not coalesce((
    select prosecdef from pg_proc
    where proname = 'is_admin' and pronamespace = 'public'::regnamespace
  ), false) then
    raise exception 'public.is_admin() must be SECURITY DEFINER';
  end if;
end $$;

-- 1. Admin-managed demo market prices.
drop policy if exists "admins insert crop prices" on public.crop_price_history;
create policy "admins insert crop prices"
  on public.crop_price_history for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists "admins update crop prices" on public.crop_price_history;
create policy "admins update crop prices"
  on public.crop_price_history for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "admins delete crop prices" on public.crop_price_history;
create policy "admins delete crop prices"
  on public.crop_price_history for delete
  to authenticated
  using (public.is_admin());

-- 2. Crop rules: a new crop needs a schedule rule, so admins manage both.
drop policy if exists "admins insert crop rules" on public.crop_rules;
create policy "admins insert crop rules"
  on public.crop_rules for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists "admins update crop rules" on public.crop_rules;
create policy "admins update crop rules"
  on public.crop_rules for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "admins delete crop rules" on public.crop_rules;
create policy "admins delete crop rules"
  on public.crop_rules for delete
  to authenticated
  using (public.is_admin());

-- 3. Listing moderation: admins can hide, unhide or delete any listing.
alter table public.marketplace_listings
  add column if not exists is_hidden boolean not null default false;

drop policy if exists "anyone signed in can read active listings" on public.marketplace_listings;
drop policy if exists "read visible listings" on public.marketplace_listings;
create policy "read visible listings"
  on public.marketplace_listings for select
  to authenticated
  using (
    (status = 'active' and not is_hidden)
    or seller_id = auth.uid()
    or public.is_admin()
  );

drop policy if exists "admins update listings" on public.marketplace_listings;
create policy "admins update listings"
  on public.marketplace_listings for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "admins delete listings" on public.marketplace_listings;
create policy "admins delete listings"
  on public.marketplace_listings for delete
  to authenticated
  using (public.is_admin());

drop policy if exists "admins delete listing photos" on public.listing_photos;
create policy "admins delete listing photos"
  on public.listing_photos for delete
  to authenticated
  using (public.is_admin());

-- Sellers can edit their own listing but must not be able to unhide it.
create or replace function public.marketplace_listings_guard_hidden()
 returns trigger
 language plpgsql
 set search_path to 'public'
as $function$
begin
  if new.is_hidden is distinct from old.is_hidden
     and auth.uid() is not null
     and not public.is_admin() then
    raise exception 'only an admin can hide or unhide a listing';
  end if;
  return new;
end;
$function$;

drop trigger if exists marketplace_listings_guard_hidden_trg on public.marketplace_listings;
create trigger marketplace_listings_guard_hidden_trg
  before update on public.marketplace_listings
  for each row execute function public.marketplace_listings_guard_hidden();

-- 4. User review: admins can read every profile.
drop policy if exists "admins read all profiles" on public.profiles;
create policy "admins read all profiles"
  on public.profiles for select
  to authenticated
  using (public.is_admin());

commit;