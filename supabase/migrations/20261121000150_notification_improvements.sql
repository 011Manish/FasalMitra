-- Notification improvements.
-- 1. New kind 'listing_status_changed'.
-- 2. Seller message names the buyer.
-- 3. Buyers who enquired hear when a listing is sold, removed or available again.
-- Safe to replay.

do $$
declare c record;
begin
  for c in
    select conname from pg_constraint
    where conrelid = 'public.notifications'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%listing_enquiry_received%'
  loop
    execute format('alter table public.notifications drop constraint %I', c.conname);
  end loop;
end $$;

alter table public.notifications
  add constraint notifications_kind_check check (kind in (
    'listing_enquiry_received', 'listing_enquiry_updated',
    'listing_moderated', 'catalog_enquiry_received',
    'listing_status_changed'
  ));

create or replace function public.notify_listing_enquiry_received()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  listing record;
begin
  select seller_id, title into listing
  from public.marketplace_listings where id = new.listing_id;

  if listing.seller_id is not null then
    perform public.notify(
      listing.seller_id, 'listing_enquiry_received', 'New enquiry',
      coalesce(new.buyer_name, 'A buyer') || ' asked about "' || listing.title
        || '": ' || left(new.message, 120),
      jsonb_build_object('listing_id', new.listing_id, 'enquiry_id', new.id)
    );
  end if;
  return new;
end;
$function$;

create or replace function public.notify_listing_status_changed()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  msg text;
  buyer uuid;
begin
  if new.status::text = 'sold' then
    msg := '"' || new.title || '" has been marked as sold.';
  elsif new.status::text = 'cancelled' then
    msg := 'The seller removed "' || new.title || '".';
  elsif new.status::text = 'active' then
    msg := '"' || new.title || '" is available again.';
  else
    return new;
  end if;

  for buyer in
    select distinct buyer_id from public.listing_enquiries where listing_id = new.id
  loop
    perform public.notify(
      buyer, 'listing_status_changed', 'Listing update', msg,
      jsonb_build_object('listing_id', new.id, 'status', new.status::text)
    );
  end loop;
  return new;
end;
$function$;

drop trigger if exists marketplace_listings_notify_status on public.marketplace_listings;
create trigger marketplace_listings_notify_status
  after update of status on public.marketplace_listings
  for each row
  when (old.status is distinct from new.status)
  execute function public.notify_listing_status_changed();