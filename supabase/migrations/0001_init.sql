-- Narro initial schema (public schema, narro_ prefix so PostgREST exposes everything by default)
-- Demo-friendly: a single fixed profile, RLS open for the demo phase.

create extension if not exists "pgcrypto";

-- =========================
-- PROFILES
-- =========================
create table if not exists public.narro_profiles (
  id uuid primary key,
  display_name text not null default 'Votre Profil',
  role_label text not null default 'Directeur',
  linkedin_connected boolean not null default true,
  weekly_target int not null default 2 check (weekly_target between 1 and 7),
  style_instructions text not null default '',
  editorial_user_tag text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.narro_keywords (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.narro_profiles(id) on delete cascade,
  label text not null,
  created_at timestamptz not null default now()
);
create index if not exists narro_keywords_profile_idx on public.narro_keywords(profile_id);

create table if not exists public.narro_tracked_influencers (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.narro_profiles(id) on delete cascade,
  handle text not null,
  tag text,
  profile_url text,
  created_at timestamptz not null default now()
);
create index if not exists narro_tracked_influencers_profile_idx on public.narro_tracked_influencers(profile_id);

create table if not exists public.narro_suggested_posts (
  id text primary key,
  profile_id uuid not null references public.narro_profiles(id) on delete cascade,
  week_offset int not null,
  type text not null check (type in ('actu','reseau')),
  category text not null,
  date_label text not null,
  text text not null,
  visual_type text not null default 'image' check (visual_type in ('image','carousel','chart','quote','none')),
  title text not null,
  posture text not null,
  angle text not null,
  status text not null default 'draft' check (status in ('draft','published','expired')),
  ordinal int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists narro_suggested_posts_profile_week_idx on public.narro_suggested_posts(profile_id, week_offset);

create table if not exists public.narro_news_sources (
  id text primary key,
  profile_id uuid not null references public.narro_profiles(id) on delete cascade,
  week_offset int not null,
  category text not null,
  title text not null,
  origin text not null,
  logo text not null default '📰',
  url text,
  ordinal int not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists narro_news_sources_profile_week_idx on public.narro_news_sources(profile_id, week_offset);

create table if not exists public.narro_network_influences (
  id text primary key,
  profile_id uuid not null references public.narro_profiles(id) on delete cascade,
  week_offset int not null,
  user_handle text not null,
  tag text,
  text text not null,
  logo text not null default '👤',
  url text,
  ordinal int not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists narro_network_influences_profile_week_idx on public.narro_network_influences(profile_id, week_offset);

create table if not exists public.narro_published_posts (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.narro_profiles(id) on delete cascade,
  title text not null,
  content text not null,
  posture text not null default 'Opinion personnelle',
  angle text not null default 'Général',
  status text not null default 'Publié',
  published_at timestamptz not null default now(),
  origin_suggested_id text references public.narro_suggested_posts(id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists narro_published_posts_profile_idx on public.narro_published_posts(profile_id, published_at desc);

create table if not exists public.narro_events (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.narro_profiles(id) on delete cascade,
  title text not null,
  description text,
  suggested_text text,
  event_date date not null,
  event_type text not null default 'webinar',
  status text not null default 'upcoming' check (status in ('upcoming','done','cancelled')),
  created_at timestamptz not null default now()
);
create index if not exists narro_events_profile_idx on public.narro_events(profile_id, event_date);

-- =========================
-- RLS (open for demo; tighten when auth ships)
-- =========================
do $$
declare
  t text;
  tables text[] := array[
    'narro_profiles','narro_keywords','narro_tracked_influencers','narro_suggested_posts',
    'narro_news_sources','narro_network_influences','narro_published_posts','narro_events'
  ];
begin
  foreach t in array tables loop
    execute format('alter table public.%I enable row level security;', t);
    execute format('drop policy if exists demo_all on public.%I;', t);
    execute format('create policy demo_all on public.%I for all to anon, authenticated using (true) with check (true);', t);
  end loop;
end$$;
