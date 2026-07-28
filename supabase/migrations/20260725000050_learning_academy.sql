create table public.learning_content (
  id uuid primary key default gen_random_uuid(),
  content_type text not null check (content_type in ('course', 'video', 'ebook', 'success_story')),
  title text not null,
  summary text not null,
  body text not null default '',
  external_url text,
  created_at timestamptz not null default now()
);

create index learning_content_type_idx on public.learning_content(content_type);

alter table public.learning_content enable row level security;

create policy "learning content is readable by any signed-in user"
  on public.learning_content for select
  to authenticated
  using (true);

-- Writes go through the service role only (SQL editor / admin scripts).
-- No insert/update/delete policy is defined for regular users on purpose.