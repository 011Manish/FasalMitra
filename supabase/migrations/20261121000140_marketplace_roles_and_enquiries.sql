-- Marketplace roles and enquiries.
-- 1. Only farmers and admins can create listings (brief A/F).
-- 2. Enquiries carry the buyer's name and phone and are validated server-side.
-- Safe to replay: triggers are dropped before being recreated.

create or replace function public.marketplace_listings_require_farmer()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.user_role;
begin
  -- SQL Editor / service role: no signed-in user, allow.
  if auth.uid() is null then
    return new;
  end if;

  select role into r from public.profiles where id = auth.uid();

  if r is null or r not in ('farmer', 'admin') then
    raise exception 'Only farmer accounts can create listings. Change your role in Profile.';
  end if;

  return new;
end;
$$;

drop trigger if exists marketplace_listings_require_farmer_trg on public.marketplace_listings;
create trigger marketplace_listings_require_farmer_trg
  before insert on public.marketplace_listings
  for each row execute function public.marketplace_listings_require_farmer();

alter table public.listing_enquiries
  add column if not exists buyer_name text;

create or replace function public.listing_enquiries_fill_buyer()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  p record;
  l record;
begin
  if auth.uid() is null then
    return new;
  end if;

  select seller_id, status into l
  from public.marketplace_listings where id = new.listing_id;

  if l.seller_id is null then
    raise exception 'Listing not found.';
  end if;
  if l.seller_id = auth.uid() then
    raise exception 'You cannot enquire on your own listing.';
  end if;
  if l.status::text <> 'active' then
    raise exception 'This listing is no longer available.';
  end if;

  select full_name, phone into p from public.profiles where id = auth.uid();

  new.buyer_name := coalesce(nullif(trim(p.full_name), ''), 'A buyer');
  new.contact_phone := coalesce(nullif(trim(new.contact_phone), ''), p.phone);
  return new;
end;
$$;

drop trigger if exists listing_enquiries_fill_buyer_trg on public.listing_enquiries;
create trigger listing_enquiries_fill_buyer_trg
  before insert on public.listing_enquiries
  for each row execute function public.listing_enquiries_fill_buyer();