-- Order status guard (brief feature F).
-- Record of the function and trigger already applied to production on 2026-11-21.
-- Sellers move an order requested -> confirmed -> completed (or cancel).
-- Buyers can only cancel. Order details cannot be edited after creation.

create or replace function public.marketplace_orders_guard_update()
 returns trigger
 language plpgsql
 set search_path to 'public'
as $function$
begin
  -- SQL Editor / service role (no signed-in user): allow.
  if auth.uid() is null then
    return new;
  end if;

  if new.listing_id <> old.listing_id
     or new.buyer_id <> old.buyer_id
     or new.seller_id <> old.seller_id
     or new.quantity <> old.quantity then
    raise exception 'order details cannot be changed';
  end if;

  if new.status = old.status then
    return new;
  end if;

  if auth.uid() = old.seller_id then
    if not (
      (old.status = 'requested' and new.status in ('confirmed', 'cancelled'))
      or (old.status = 'confirmed' and new.status in ('completed', 'cancelled'))
    ) then
      raise exception 'invalid status change from % to %', old.status, new.status;
    end if;
  elsif auth.uid() = old.buyer_id then
    if not (new.status = 'cancelled' and old.status in ('requested', 'confirmed')) then
      raise exception 'buyers can only cancel an order';
    end if;
  else
    raise exception 'not allowed';
  end if;

  return new;
end;
$function$;

drop trigger if exists marketplace_orders_guard_update_trg on public.marketplace_orders;
create trigger marketplace_orders_guard_update_trg
  before update on public.marketplace_orders
  for each row execute function public.marketplace_orders_guard_update();