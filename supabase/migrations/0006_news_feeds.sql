-- RSS / Atom feeds (Google Alerts compatible) that feed "NEWS DU SECTEUR".

create table if not exists public.narro_news_feeds (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.narro_profiles(id) on delete cascade,
  url text not null,
  name text not null default 'Source',
  category text not null default 'Veille',
  active boolean not null default true,
  last_fetched_at timestamptz,
  last_status text,
  created_at timestamptz not null default now()
);
create index if not exists narro_news_feeds_profile_idx on public.narro_news_feeds(profile_id);
create unique index if not exists narro_news_feeds_unique
  on public.narro_news_feeds(profile_id, url);

alter table public.narro_news_feeds enable row level security;
drop policy if exists self_read on public.narro_news_feeds;
drop policy if exists self_write on public.narro_news_feeds;
drop policy if exists self_update on public.narro_news_feeds;
drop policy if exists self_delete on public.narro_news_feeds;
create policy self_read on public.narro_news_feeds for select to authenticated
  using (profile_id = auth.uid() or public.narro_current_role() in ('admin','super_admin'));
create policy self_write on public.narro_news_feeds for insert to authenticated
  with check (profile_id = auth.uid());
create policy self_update on public.narro_news_feeds for update to authenticated
  using (profile_id = auth.uid()) with check (profile_id = auth.uid());
create policy self_delete on public.narro_news_feeds for delete to authenticated
  using (profile_id = auth.uid());

-- Track which feed an item came from + the original URL of the article
alter table public.narro_news_sources
  add column if not exists feed_id uuid references public.narro_news_feeds(id) on delete set null,
  add column if not exists published_at timestamptz;

create index if not exists narro_news_sources_feed_idx on public.narro_news_sources(feed_id);
