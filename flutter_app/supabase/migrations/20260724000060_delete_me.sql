-- Self-service account deletion. The client can call this RPC to wipe
-- their auth.users row; ON DELETE CASCADE on profiles / farm_profiles /
-- schedule_items handles the rest.
--
-- SECURITY DEFINER so it can reach auth.users, but the very first line
-- asserts that we're only ever deleting the caller.

create or replace function public.delete_current_user()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  caller uuid := auth.uid();
begin
  if caller is null then
    raise exception 'not authenticated';
  end if;

  delete from auth.users where id = caller;
end;
$$;

revoke all on function public.delete_current_user() from public;
grant execute on function public.delete_current_user() to authenticated;
