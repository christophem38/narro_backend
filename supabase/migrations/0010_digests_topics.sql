-- Weekly AI digest + hot topics caching.

create table if not exists public.narro_weekly_digests (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.narro_profiles(id) on delete cascade,
  week_start date not null,
  payload jsonb not null,
  created_at timestamptz not null default now()
);
create unique index if not exists narro_weekly_digests_unique
  on public.narro_weekly_digests(profile_id, week_start);

alter table public.narro_weekly_digests enable row level security;
drop policy if exists self_read on public.narro_weekly_digests;
drop policy if exists self_write on public.narro_weekly_digests;
create policy self_read on public.narro_weekly_digests for select to authenticated
  using (profile_id = auth.uid() or public.narro_current_role() in ('admin','super_admin'));
create policy self_write on public.narro_weekly_digests for insert to authenticated
  with check (profile_id = auth.uid());

-- Hot topics cache (cheap re-compute every few hours)
create table if not exists public.narro_hot_topics (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.narro_profiles(id) on delete cascade,
  generated_at timestamptz not null default now(),
  payload jsonb not null
);
create index if not exists narro_hot_topics_profile_idx
  on public.narro_hot_topics(profile_id, generated_at desc);
alter table public.narro_hot_topics enable row level security;
drop policy if exists self_read on public.narro_hot_topics;
drop policy if exists self_write on public.narro_hot_topics;
create policy self_read on public.narro_hot_topics for select to authenticated
  using (profile_id = auth.uid() or public.narro_current_role() in ('admin','super_admin'));
create policy self_write on public.narro_hot_topics for insert to authenticated
  with check (profile_id = auth.uid());
