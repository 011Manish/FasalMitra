-- In-app notifications (brief section J): enquiries on listings and the
-- catalogue, and admin actions on a seller's listing. Rows are created only by
-- the triggers below; users can read their own, mark them read and delete them.
-- Runs as one transaction: if any step fails, nothing is changed.

begin;

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in (
    'listing_enquiry_received', 'listing_enquiry_updated',
    'listing_moderated', 'catalog_enquiry_received'
  )),
  title text not null,
  body text,
  data jsonb not null default '{}'::jsonb, -- ids the app needs to open the related screen
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index if not exists notifications_user_created_idx
  on public.notifications (user_id, created_at desc);
create index if not exists notifications_user_unread_idx
  on public.notifications (user_id) where read_at is null;

alter table public.notifications enable row level security;

drop policy if exists "read own notifications" on public.notifications;
create policy "read own notifications"
  on public.notifications for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "mark own notifications read" on public.notifications;
create policy "mark own notifications read"
  on public.notifications for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "delete own notifications" on public.notifications;
create policy "delete own notifications"
  on public.notifications for delete
  to authenticated
  using (user_id = auth.uid());

-- Users may only change read_at, and never create rows themselves.
revoke insert, update on public.notifications from anon, authenticated;
grant update (read_at) on public.notifications to authenticated;

-- Single entry point for creating a notification. Not callable from the app.
create or replace function public.notify(
  p_user uuid, p_kind text, p_title text, p_body text, p_data jsonb default '{}'::jsonb
) returns void
 language sql
 security definer
 set search_path to 'public'
as $function$
  insert into public.notifications (user_id, kind, title, body, data)
  values (p_user, p_kind, p_title, p_body, p_data);
$function$;

revoke all on function public.notify(uuid, text, text, text, jsonb)
  from public, anon, authenticated;

-- A buyer sends an enquiry: tell the seller.
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
      'Someone asked about "' || listing.title || '": ' || left(new.message, 120),
      jsonb_build_object('listing_id', new.listing_id, 'enquiry_id', new.id)
    );
  end if;
  return new;
end;
$function$;

drop trigger if exists listing_enquiries_notify_seller on public.listing_enquiries;
create trigger listing_enquiries_notify_seller
  after insert on public.listing_enquiries
  for each row execute function public.notify_listing_enquiry_received();

-- A seller changes the enquiry status: tell the buyer.
create or replace function public.notify_listing_enquiry_updated()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  listing_title text;
begin
  select title into listing_title
  from public.marketplace_listings where id = new.listing_id;

  perform public.notify(
    new.buyer_id, 'listing_enquiry_updated', 'Enquiry update',
    'The seller marked your enquiry on "' || coalesce(listing_title, 'a listing')
      || '" as ' || new.status || '.',
    jsonb_build_object('listing_id', new.listing_id, 'enquiry_id', new.id,
                       'status', new.status)
  );
  return new;
end;
$function$;

drop trigger if exists listing_enquiries_notify_buyer on public.listing_enquiries;
create trigger listing_enquiries_notify_buyer
  after update of status on public.listing_enquiries
  for each row
  when (old.status is distinct from new.status)
  execute function public.notify_listing_enquiry_updated();

-- An admin hides or unhides a listing: tell the seller.
create or replace function public.notify_listing_visibility_changed()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
begin
  perform public.notify(
    new.seller_id, 'listing_moderated',
    case when new.is_hidden then 'Listing hidden' else 'Listing visible again' end,
    case when new.is_hidden
      then 'An admin hid "' || new.title || '". Contact support if you think this is a mistake.'
      else 'An admin made "' || new.title || '" visible again.'
    end,
    jsonb_build_object('listing_id', new.id,
                       'action', case when new.is_hidden then 'hidden' else 'unhidden' end)
  );
  return new;
end;
$function$;

drop trigger if exists marketplace_listings_notify_hidden on public.marketplace_listings;
create trigger marketplace_listings_notify_hidden
  after update of is_hidden on public.marketplace_listings
  for each row
  when (old.is_hidden is distinct from new.is_hidden)
  execute function public.notify_listing_visibility_changed();

-- An admin deletes someone else's listing: tell the seller.
create or replace function public.notify_listing_removed()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
begin
  if auth.uid() is not null and auth.uid() <> old.seller_id and public.is_admin() then
    perform public.notify(
      old.seller_id, 'listing_moderated', 'Listing removed',
      'An admin removed "' || old.title || '".',
      jsonb_build_object('action', 'removed')
    );
  end if;
  return old;
end;
$function$;

drop trigger if exists marketplace_listings_notify_removed on public.marketplace_listings;
create trigger marketplace_listings_notify_removed
  after delete on public.marketplace_listings
  for each row execute function public.notify_listing_removed();

-- Someone sends a catalogue enquiry: tell every admin.
create or replace function public.notify_catalog_enquiry_received()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
declare
  product_name text;
begin
  select name into product_name
  from public.catalog_products where id = new.product_id;

  insert into public.notifications (user_id, kind, title, body, data)
  select id, 'catalog_enquiry_received', 'New catalogue enquiry',
         'Enquiry about "' || coalesce(product_name, 'a product') || '": ' || left(new.message, 120),
         jsonb_build_object('product_id', new.product_id, 'enquiry_id', new.id)
  from public.profiles
  where role = 'admin';
  return new;
end;
$function$;

drop trigger if exists catalog_enquiries_notify_admins on public.catalog_enquiries;
create trigger catalog_enquiries_notify_admins
  after insert on public.catalog_enquiries
  for each row execute function public.notify_catalog_enquiry_received();

-- Live updates in the app (unread badge and list).
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime'
         and schemaname = 'public' and tablename = 'notifications'
     ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;

commit;