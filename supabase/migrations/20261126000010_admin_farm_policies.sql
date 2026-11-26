-- Admin dashboard: let admins review, edit and delete farm profiles.
-- Admin status always comes from public.is_admin() (SECURITY DEFINER).
-- Normal users keep only their own rows through the existing owner policies.
-- Read this file, then run it once in the Supabase SQL Editor.

begin;

drop policy if exists "admins read farm profiles" on public.farm_profiles;
create policy "admins read farm profiles"
  on public.farm_profiles for select
  to authenticated
  using (public.is_admin());

drop policy if exists "admins update farm profiles" on public.farm_profiles;
create policy "admins update farm profiles"
  on public.farm_profiles for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "admins delete farm profiles" on public.farm_profiles;
create policy "admins delete farm profiles"
  on public.farm_profiles for delete
  to authenticated
  using (public.is_admin());

commit;
