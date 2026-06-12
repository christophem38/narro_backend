-- Extend feeds to also feed the Lab's "Réseau & Influences" column,
-- and prepare the columns required for a real LinkedIn OAuth connection.

-- 1) narro_news_feeds : a feed can now target either column
alter table public.narro_news_feeds
  add column if not exists target text not null default 'news' check (target in ('news','influences')),
  add column if not exists network text not null default 'rss' check (network in ('rss','twitter','linkedin','manual'));

create index if not exists narro_news_feeds_target_idx on public.narro_news_feeds(target);

-- 2) narro_network_influences : attribution + author + published_at
alter table public.narro_network_influences
  add column if not exists feed_id uuid references public.narro_news_feeds(id) on delete set null,
  add column if not exists author_url text,
  add column if not exists post_url text,
  add column if not exists published_at timestamptz;

create index if not exists narro_network_influences_feed_idx
  on public.narro_network_influences(feed_id);

-- 3) LinkedIn connection on the profile
alter table public.narro_profiles
  add column if not exists linkedin_user_id text,
  add column if not exists linkedin_access_token text,
  add column if not exists linkedin_refresh_token text,
  add column if not exists linkedin_expires_at timestamptz,
  add column if not exists linkedin_profile_url text;

create index if not exists narro_profiles_linkedin_user_id_idx
  on public.narro_profiles(linkedin_user_id);
