create table public.experts (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  specialty text not null,
  bio text not null,
  photo_url text,
  created_at timestamptz not null default now()
);

alter table public.experts enable row level security;

create policy "experts are readable by any signed-in user"
  on public.experts for select
  to authenticated
  using (true);

-- Writes go through the service role only (migrations / admin scripts).
-- No insert/update/delete policy is defined for regular users on purpose.

create table public.consultation_appointments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  expert_id uuid not null references public.experts(id),
  farm_id uuid references public.farm_profiles(id) on delete set null,
  requested_at timestamptz not null default now(),
  scheduled_for timestamptz,
  status text not null default 'pending'
    check (status in ('pending', 'confirmed', 'completed', 'cancelled'))
);

create index consultation_appointments_user_idx
  on public.consultation_appointments(user_id, requested_at desc);

alter table public.consultation_appointments enable row level security;

create policy "farmers read their own appointments"
  on public.consultation_appointments for select
  using (auth.uid() = user_id);

create policy "farmers create their own appointments"
  on public.consultation_appointments for insert
  with check (auth.uid() = user_id);

create policy "farmers update their own appointments"
  on public.consultation_appointments for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "farmers delete their own appointments"
  on public.consultation_appointments for delete
  using (auth.uid() = user_id);

create table public.consultation_messages (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references public.consultation_appointments(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

create index consultation_messages_appointment_idx
  on public.consultation_messages(appointment_id, created_at);

alter table public.consultation_messages enable row level security;

create policy "participants read consultation messages"
  on public.consultation_messages for select
  using (
    exists (
      select 1 from public.consultation_appointments a
      where a.id = consultation_messages.appointment_id and a.user_id = auth.uid()
    )
  );

create policy "participants send consultation messages"
  on public.consultation_messages for insert
  with check (
    auth.uid() = sender_id
    and exists (
      select 1 from public.consultation_appointments a
      where a.id = consultation_messages.appointment_id and a.user_id = auth.uid()
    )
  );
