alter table public.learning_content
  add column category text not null default 'general'
    check (category in (
      'general', 'vegetable_farming', 'rice', 'maize', 'soil_testing',
      'compost_fertilizer', 'irrigation', 'pest_disease', 'harvesting_selling'
    )),
  add column language text not null default 'en'
    check (language in ('ne', 'hi', 'en')),
  add column thumbnail_url text,
  add column updated_at timestamptz not null default now();

create index learning_content_category_idx on public.learning_content(category);
create index learning_content_language_idx on public.learning_content(language);

create trigger learning_content_touch_updated_at
  before update on public.learning_content
  for each row execute function public.touch_updated_at();

-- Admins can add, edit and delete tutorials. Everyone signed in can still read.
create policy "admins insert learning content"
  on public.learning_content for insert
  to authenticated
  with check (public.is_admin());

create policy "admins update learning content"
  on public.learning_content for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy "admins delete learning content"
  on public.learning_content for delete
  to authenticated
  using (public.is_admin());