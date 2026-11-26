-- Record only: already applied to production
-- Catalogue policy names. 20261121000020_catalog_products.sql creates these
-- policies under other names. Production has the names below, with the same
-- conditions. This file drops the names from that file and creates the
-- production names. In production the dropped names do not exist, so nothing
-- changes there. Safe to run again.

-- Names from 20261121000020 (they do not exist in production)
drop policy if exists "catalog products select" on public.catalog_products;
drop policy if exists "catalog products admin insert" on public.catalog_products;
drop policy if exists "catalog products admin update" on public.catalog_products;
drop policy if exists "catalog products admin delete" on public.catalog_products;
drop policy if exists "catalog enquiries select" on public.catalog_enquiries;
drop policy if exists "catalog enquiries insert own" on public.catalog_enquiries;
drop policy if exists "catalog enquiries admin update" on public.catalog_enquiries;

-- catalog_products (production names)
drop policy if exists "catalog readable by signed-in users" on public.catalog_products;
create policy "catalog readable by signed-in users"
  on public.catalog_products for select
  to authenticated
  using (is_active or public.is_admin());

drop policy if exists "admins insert catalog products" on public.catalog_products;
create policy "admins insert catalog products"
  on public.catalog_products for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists "admins update catalog products" on public.catalog_products;
create policy "admins update catalog products"
  on public.catalog_products for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "admins delete catalog products" on public.catalog_products;
create policy "admins delete catalog products"
  on public.catalog_products for delete
  to authenticated
  using (public.is_admin());

-- catalog_enquiries (production names)
drop policy if exists "users read own enquiries, admins read all" on public.catalog_enquiries;
create policy "users read own enquiries, admins read all"
  on public.catalog_enquiries for select
  to authenticated
  using (user_id = auth.uid() or public.is_admin());

drop policy if exists "users create own enquiries" on public.catalog_enquiries;
create policy "users create own enquiries"
  on public.catalog_enquiries for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists "admins update enquiries" on public.catalog_enquiries;
create policy "admins update enquiries"
  on public.catalog_enquiries for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());