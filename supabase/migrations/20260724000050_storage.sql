-- Private bucket for anything a farmer uploads (plant scan photos in Phase 2,
-- but the pattern belongs here now so we're not tempted to make a public
-- bucket "just for testing" later).

insert into storage.buckets (id, name, public)
values ('farm-media', 'farm-media', false)
on conflict (id) do nothing;

-- File keys follow the convention: <user_id>/<farm_id>/<uuid>-<filename>
-- so we can enforce ownership by looking at the first path segment.

create policy "farmers read their own farm media"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'farm-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "farmers upload into their own folder"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'farm-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "farmers update their own farm media"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'farm-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "farmers delete their own farm media"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'farm-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
