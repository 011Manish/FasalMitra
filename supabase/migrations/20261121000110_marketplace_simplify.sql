-- Marketplace to brief section F: produce listings with location, availability
-- date and photos, plus buyer enquiries. Removes auctions, bids and orders,
-- which the brief does not ask for. All four tables were empty when this was
-- written. Runs as one transaction: if any step fails, nothing is changed.

begin;

-- Abort if any function we are not dropping still uses the objects being removed.
do $$
declare
  offenders text;
begin
  select string_agg(proname, ', ') into offenders
  from pg_proc
  where pronamespace = 'public'::regnamespace
    and proname not in ('marketplace_orders_guard_update',
                        'marketplace_validate_bid',
                        'marketplace_validate_order')
    and (prosrc ilike '%listing_type%'
         or prosrc ilike '%auction_end_at%'
         or prosrc ilike '%item_category%'
         or prosrc ilike '%marketplace_bids%'
         or prosrc ilike '%marketplace_orders%');
  if offenders is not null then
    raise exception 'Functions still reference removed objects: %', offenders;
  end if;
end $$;

-- 1. Remove auctions, bids and orders (no CASCADE: a hidden dependency makes this fail).
drop view if exists public.marketplace_listings_with_highest_bid;
drop table if exists public.marketplace_bids;
drop table if exists public.marketplace_orders;
drop function if exists public.marketplace_orders_guard_update();
drop function if exists public.marketplace_validate_bid();
drop function if exists public.marketplace_validate_order();

-- 2. Listings: produce only, with location and availability date.
alter table public.marketplace_listings
  drop column if exists listing_type,
  drop column if exists auction_end_at,
  drop column if exists item_category,
  add column if not exists state_province text,
  add column if not exists district text,
  add column if not exists municipality text,
  add column if not exists available_from date;

drop type if exists public.listing_type;
drop type if exists public.listing_category;
drop type if exists public.order_status;

create index if not exists marketplace_listings_status_created_idx
  on public.marketplace_listings (status, created_at desc);
create index if not exists marketplace_listings_district_idx
  on public.marketplace_listings (district);

-- 3. Listing photos. Storage path convention: <seller_id>/<listing_id>/<file>
create table if not exists public.listing_photos (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.marketplace_listings(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null unique,
  created_at timestamptz not null default now()
);

create index if not exists listing_photos_listing_idx
  on public.listing_photos (listing_id);

alter table public.listing_photos enable row level security;

-- The subquery runs under the listing policies, so photos follow listing visibility.
drop policy if exists "read photos of visible listings" on public.listing_photos;
create policy "read photos of visible listings"
  on public.listing_photos for select
  to authenticated
  using (exists (
    select 1 from public.marketplace_listings l
    where l.id = listing_photos.listing_id
  ));

drop policy if exists "sellers add photos to their own listings" on public.listing_photos;
create policy "sellers add photos to their own listings"
  on public.listing_photos for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.marketplace_listings l
      where l.id = listing_photos.listing_id and l.seller_id = auth.uid()
    )
  );

drop policy if exists "sellers delete their own listing photos" on public.listing_photos;
create policy "sellers delete their own listing photos"
  on public.listing_photos for delete
  to authenticated
  using (user_id = auth.uid());

-- 4. Buyer enquiries.
create table if not exists public.listing_enquiries (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.marketplace_listings(id) on delete cascade,
  buyer_id uuid not null references auth.users(id) on delete cascade,
  message text not null check (char_length(message) between 1 and 1000),
  contact_phone text,
  status text not null default 'new'
    check (status in ('new', 'contacted', 'closed')),
  created_at timestamptz not null default now()
);

create index if not exists listing_enquiries_listing_idx
  on public.listing_enquiries (listing_id);
create index if not exists listing_enquiries_buyer_idx
  on public.listing_enquiries (buyer_id);

alter table public.listing_enquiries enable row level security;

drop policy if exists "buyer, listing seller and admin read enquiries" on public.listing_enquiries;
create policy "buyer, listing seller and admin read enquiries"
  on public.listing_enquiries for select
  to authenticated
  using (
    buyer_id = auth.uid()
    or public.is_admin()
    or exists (
      select 1 from public.marketplace_listings l
      where l.id = listing_enquiries.listing_id and l.seller_id = auth.uid()
    )
  );

-- Buyers can enquire only on active listings that are not their own.
drop policy if exists "buyers send enquiries" on public.listing_enquiries;
create policy "buyers send enquiries"
  on public.listing_enquiries for insert
  to authenticated
  with check (
    buyer_id = auth.uid()
    and exists (
      select 1 from public.marketplace_listings l
      where l.id = listing_enquiries.listing_id
        and l.status = 'active'
        and l.seller_id <> auth.uid()
    )
  );

drop policy if exists "sellers update enquiry status" on public.listing_enquiries;
create policy "sellers update enquiry status"
  on public.listing_enquiries for update
  to authenticated
  using (exists (
    select 1 from public.marketplace_listings l
    where l.id = listing_enquiries.listing_id and l.seller_id = auth.uid()
  ))
  with check (exists (
    select 1 from public.marketplace_listings l
    where l.id = listing_enquiries.listing_id and l.seller_id = auth.uid()
  ));

-- Sellers may change the status only, never the buyer's message or phone.
revoke update on public.listing_enquiries from anon, authenticated;
grant update (status) on public.listing_enquiries to authenticated;

-- 5. Private storage bucket for listing photos (viewed through signed URLs).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('listing-media', 'listing-media', false, 5242880,
        array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

drop policy if exists "signed in users read listing media" on storage.objects;
create policy "signed in users read listing media"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'listing-media');

drop policy if exists "sellers upload into their own listing folder" on storage.objects;
create policy "sellers upload into their own listing folder"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'listing-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "sellers update their own listing media" on storage.objects;
create policy "sellers update their own listing media"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'listing-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "sellers delete their own listing media" on storage.objects;
create policy "sellers delete their own listing media"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'listing-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

commit;