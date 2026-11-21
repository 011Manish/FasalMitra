create type public.user_role as enum ('farmer', 'buyer', 'admin');

alter table public.profiles
  add column role public.user_role not null default 'farmer',
  add column country text check (country in ('NP', 'IN')),
  add column phone text check (phone is null or char_length(phone) between 7 and 20);

-- Helper used by every admin-only policy later.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

grant execute on function public.is_admin() to authenticated;

-- Without this, any user could update their own row and make themselves admin.
-- From the app (auth.uid() is set) nobody can grant admin; from the SQL editor
-- (auth.uid() is null) you can.
create or replace function public.profiles_protect_role()
returns trigger
language plpgsql
as $$
begin
  if auth.uid() is not null then
    if tg_op = 'INSERT' and new.role = 'admin' then
      raise exception 'cannot create an admin profile';
    end if;
    if tg_op = 'UPDATE' and new.role = 'admin' and old.role <> 'admin' then
      raise exception 'cannot promote yourself to admin';
    end if;
  end if;
  return new;
end;
$$;

create trigger profiles_protect_role_trg
  before insert or update on public.profiles
  for each row execute function public.profiles_protect_role();

-- Sign-up now also stores role, country and phone from the form.
-- Only farmer/buyer are accepted from the client; anything else becomes farmer.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role, country, phone)
  values (
    new.id,
    new.raw_user_meta_data->>'full_name',
    case when new.raw_user_meta_data->>'role' in ('farmer', 'buyer')
         then (new.raw_user_meta_data->>'role')::public.user_role
         else 'farmer' end,
    case when new.raw_user_meta_data->>'country' in ('NP', 'IN')
         then new.raw_user_meta_data->>'country' end,
    new.raw_user_meta_data->>'phone'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;