-- Product catalogue (brief feature G).
-- Record of changes already applied to production on 2026-11-21.
-- Written to be safe to re-run. Sample products are not included here.

create table if not exists public.catalog_products (
  id uuid primary key default gen_random_uuid(),
  category text not null
    check (category in ('seed', 'fertilizer', 'tool', 'irrigation')),
  name text not null,
  name_ne text,
  description text,
  image_url text,
  indicative_price numeric(12, 2),
  currency text not null default 'NPR',
  unit text,
  seller_name text,
  seller_phone text,
  seller_address text,
  availability text not null default 'in_stock'
    check (availability in ('in_stock', 'out_of_stock', 'limited')),
  is_demo boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.catalog_enquiries (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.catalog_products(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  message text not null check (char_length(message) between 1 and 1000),
  contact_phone text,
  status text not null default 'new'
    check (status in ('new', 'contacted', 'closed')),
  created_at timestamptz not null default now()
);

create index if not exists catalog_products_category_idx
  on public.catalog_products(category);
create index if not exists catalog_enquiries_product_idx
  on public.catalog_enquiries(product_id);
create index if not exists catalog_enquiries_user_idx
  on public.catalog_enquiries(user_id);

drop trigger if exists catalog_products_touch_updated_at on public.catalog_products;
create trigger catalog_products_touch_updated_at
  before update on public.catalog_products
  for each row execute function public.touch_updated_at();

alter table public.catalog_products enable row level security;
alter table public.catalog_enquiries enable row level security;

-- Products: signed-in users read active items; admins manage everything.
drop policy if exists "catalog products select" on public.catalog_products;
create policy "catalog products select"
  on public.catalog_products for select
  to authenticated
  using (is_active or public.is_admin());

drop policy if exists "catalog products admin insert" on public.catalog_products;
create policy "catalog products admin insert"
  on public.catalog_products for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists "catalog products admin update" on public.catalog_products;
create policy "catalog products admin update"
  on public.catalog_products for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "catalog products admin delete" on public.catalog_products;
create policy "catalog products admin delete"
  on public.catalog_products for delete
  to authenticated
  using (public.is_admin());

-- Enquiries: users see and create their own; only admins update status.
drop policy if exists "catalog enquiries select" on public.catalog_enquiries;
create policy "catalog enquiries select"
  on public.catalog_enquiries for select
  to authenticated
  using (auth.uid() = user_id or public.is_admin());

drop policy if exists "catalog enquiries insert own" on public.catalog_enquiries;
create policy "catalog enquiries insert own"
  on public.catalog_enquiries for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "catalog enquiries admin update" on public.catalog_enquiries;
create policy "catalog enquiries admin update"
  on public.catalog_enquiries for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());