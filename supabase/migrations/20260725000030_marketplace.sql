-- Marketplace: farmers list crops/inputs for sale (fixed price or auction),
-- other farmers place bids or request to buy. No payment processing here —
-- that's a separate integration (Khalti/eSewa) for a later phase. This is
-- the listing / bidding / order-request layer only.

create type public.listing_type as enum ('fixed_price', 'auction');
create type public.listing_category as enum ('crop', 'seed', 'fertilizer', 'pesticide', 'tool');
create type public.listing_status as enum ('active', 'sold', 'cancelled', 'expired');
create type public.order_status as enum ('requested', 'confirmed', 'cancelled', 'completed');

create table public.marketplace_listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references auth.users(id) on delete cascade,
  farm_id uuid references public.farm_profiles(id) on delete set null,
  listing_type public.listing_type not null,
  item_category public.listing_category not null,
  title text not null check (char_length(title) between 1 and 120),
  description text check (description is null or char_length(description) <= 2000),
  unit text not null check (char_length(unit) between 1 and 20),
  quantity numeric(10, 2) not null check (quantity > 0),
  price numeric(12, 2) not null check (price > 0),
  currency text not null default 'NPR',
  auction_end_at timestamptz,
  status public.listing_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint auction_requires_end_time check (
    (listing_type = 'auction' and auction_end_at is not null and auction_end_at > created_at)
    or (listing_type = 'fixed_price' and auction_end_at is null)
  )
);

create index marketplace_listings_status_idx on public.marketplace_listings(status);
create index marketplace_listings_seller_id_idx on public.marketplace_listings(seller_id);
create index marketplace_listings_category_idx on public.marketplace_listings(item_category);

alter table public.marketplace_listings enable row level security;

create policy "anyone signed in can read active listings"
  on public.marketplace_listings for select
  to authenticated
  using (status = 'active' or seller_id = auth.uid());

create policy "farmers create their own listings"
  on public.marketplace_listings for insert
  with check (seller_id = auth.uid());

create policy "sellers update their own listings"
  on public.marketplace_listings for update
  using (seller_id = auth.uid())
  with check (seller_id = auth.uid());

create policy "sellers delete their own listings"
  on public.marketplace_listings for delete
  using (seller_id = auth.uid());

create trigger marketplace_listings_touch_updated_at
  before update on public.marketplace_listings
  for each row execute function public.touch_updated_at();

-- Bids (auction listings only) ----------------------------------------

create table public.marketplace_bids (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.marketplace_listings(id) on delete cascade,
  bidder_id uuid not null references auth.users(id) on delete cascade,
  amount numeric(12, 2) not null check (amount > 0),
  created_at timestamptz not null default now()
);

create index marketplace_bids_listing_id_idx on public.marketplace_bids(listing_id, amount desc);

alter table public.marketplace_bids enable row level security;

create policy "bids on a listing are readable by anyone signed in"
  on public.marketplace_bids for select
  to authenticated
  using (true);

create policy "farmers place their own bids"
  on public.marketplace_bids for insert
  with check (bidder_id = auth.uid());

-- No update/delete policy on purpose: bids are immutable once placed.

-- Enforce auction bidding rules server-side so a malicious client can't
-- bypass the Flutter-side checks: must be an active, non-expired auction,
-- bidder can't be the seller, and the bid must beat the current best offer.
create or replace function public.marketplace_validate_bid()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  listing public.marketplace_listings%rowtype;
  current_best numeric(12, 2);
begin
  select * into listing from public.marketplace_listings where id = new.listing_id;

  if listing.id is null then
    raise exception 'listing not found';
  end if;

  if listing.listing_type <> 'auction' then
    raise exception 'this listing is not an auction';
  end if;

  if listing.status <> 'active' then
    raise exception 'this auction is no longer active';
  end if;

  if listing.auction_end_at <= now() then
    raise exception 'this auction has ended';
  end if;

  if listing.seller_id = new.bidder_id then
    raise exception 'you cannot bid on your own listing';
  end if;

  select coalesce(max(amount), listing.price - 0.01)
    into current_best
    from public.marketplace_bids
    where listing_id = new.listing_id;

  if new.amount <= current_best then
    raise exception 'bid must be higher than the current best offer (%.2f)', current_best;
  end if;

  return new;
end;
$$;

create trigger marketplace_bids_validate
  before insert on public.marketplace_bids
  for each row execute function public.marketplace_validate_bid();

-- Convenience view: each active auction listing with its current best bid,
-- so the app doesn't need a second round-trip just to show "current price".
create view public.marketplace_listings_with_highest_bid as
select
  l.*,
  (select max(b.amount) from public.marketplace_bids b where b.listing_id = l.id) as highest_bid,
  (select count(*) from public.marketplace_bids b where b.listing_id = l.id) as bid_count
from public.marketplace_listings l;

alter view public.marketplace_listings_with_highest_bid set (security_invoker = true);

-- Orders (fixed-price "request to buy") ---------------------------------

create table public.marketplace_orders (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.marketplace_listings(id) on delete cascade,
  buyer_id uuid not null references auth.users(id) on delete cascade,
  seller_id uuid not null references auth.users(id) on delete cascade,
  quantity numeric(10, 2) not null check (quantity > 0),
  status public.order_status not null default 'requested',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint buyer_is_not_seller check (buyer_id <> seller_id)
);

create index marketplace_orders_listing_id_idx on public.marketplace_orders(listing_id);
create index marketplace_orders_buyer_id_idx on public.marketplace_orders(buyer_id);
create index marketplace_orders_seller_id_idx on public.marketplace_orders(seller_id);

alter table public.marketplace_orders enable row level security;

create policy "buyers and sellers read their own orders"
  on public.marketplace_orders for select
  using (buyer_id = auth.uid() or seller_id = auth.uid());

create policy "buyers create order requests"
  on public.marketplace_orders for insert
  with check (buyer_id = auth.uid());

-- The client only ever sends listing_id + quantity. seller_id is derived
-- here (never trusted from the client) so a buyer can't misattribute an
-- order to a different seller than the one who actually owns the listing.
create or replace function public.marketplace_validate_order()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  listing public.marketplace_listings%rowtype;
begin
  select * into listing from public.marketplace_listings where id = new.listing_id;

  if listing.id is null then
    raise exception 'listing not found';
  end if;

  if listing.listing_type <> 'fixed_price' then
    raise exception 'this listing is an auction, place a bid instead';
  end if;

  if listing.status <> 'active' then
    raise exception 'this listing is no longer active';
  end if;

  if listing.seller_id = new.buyer_id then
    raise exception 'you cannot buy your own listing';
  end if;

  if new.quantity > listing.quantity then
    raise exception 'requested quantity exceeds available quantity';
  end if;

  new.seller_id := listing.seller_id;
  return new;
end;
$$;

create trigger marketplace_orders_validate
  before insert on public.marketplace_orders
  for each row execute function public.marketplace_validate_order();

create policy "buyers and sellers update their own orders"
  on public.marketplace_orders for update
  using (buyer_id = auth.uid() or seller_id = auth.uid())
  with check (buyer_id = auth.uid() or seller_id = auth.uid());

create trigger marketplace_orders_touch_updated_at
  before update on public.marketplace_orders
  for each row execute function public.touch_updated_at();
