-- Pitch deck features: onboarding, maturity, pertinence, calendar, stats, plan 90j, teams.

-- =========================
-- 1) Profile : country, sector, target audience, objective, tone preset,
--    onboarding flags, maturity level, first-speech mode, subscription tier
-- =========================
alter table public.narro_profiles
  add column if not exists country_code text default 'FR',
  add column if not exists sector text,
  add column if not exists target_audience text,
  add column if not exists primary_objective text,
  add column if not exists tone_preset text default 'expert',
  add column if not exists onboarded boolean not null default false,
  add column if not exists maturity_level int not null default 1 check (maturity_level between 1 and 4),
  add column if not exists first_speech_mode boolean not null default false,
  add column if not exists subscription_tier text not null default 'free' check (subscription_tier in ('free','solo','pro','team','enterprise')),
  add column if not exists subscription_started_at timestamptz;

-- =========================
-- 2) Published posts : engagement stats + scheduling
-- =========================
alter table public.narro_published_posts
  add column if not exists scheduled_at timestamptz,
  add column if not exists like_count int default 0,
  add column if not exists share_count int default 0,
  add column if not exists comment_count int default 0,
  add column if not exists reach_count int default 0;

-- Update status enum-ish to allow 'Programmé'
-- (status is plain text, no change required)

-- =========================
-- 3) Suggested posts : pertinence score JSON
-- =========================
alter table public.narro_suggested_posts
  add column if not exists pertinence_scores jsonb default '{
    "role_alignment": 85,
    "audience_interest": 80,
    "topicality": 88,
    "differentiation": 70,
    "clarity": 78,
    "reputation_risk": 92,
    "conversation_potential": 75
  }'::jsonb,
  add column if not exists exposure_level text default 'moderate' check (exposure_level in ('low','moderate','high'));

-- =========================
-- 4) Used angles memory
-- =========================
create table if not exists public.narro_used_angles (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.narro_profiles(id) on delete cascade,
  angle text not null,
  used_at timestamptz not null default now()
);
create index if not exists narro_used_angles_profile_idx on public.narro_used_angles(profile_id, used_at desc);
alter table public.narro_used_angles enable row level security;
drop policy if exists self_read on public.narro_used_angles;
drop policy if exists self_write on public.narro_used_angles;
drop policy if exists self_update on public.narro_used_angles;
drop policy if exists self_delete on public.narro_used_angles;
create policy self_read on public.narro_used_angles for select to authenticated
  using (profile_id = auth.uid() or public.narro_current_role() in ('admin','super_admin'));
create policy self_write on public.narro_used_angles for insert to authenticated
  with check (profile_id = auth.uid());
create policy self_delete on public.narro_used_angles for delete to authenticated
  using (profile_id = auth.uid());

-- =========================
-- 5) Progress tasks (90-day plan)
-- =========================
create table if not exists public.narro_progress_tasks (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.narro_profiles(id) on delete cascade,
  month_index int not null check (month_index between 1 and 3),
  ordinal int not null default 0,
  title text not null,
  done boolean not null default false,
  done_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists narro_progress_profile_idx on public.narro_progress_tasks(profile_id, month_index, ordinal);
alter table public.narro_progress_tasks enable row level security;
drop policy if exists self_read on public.narro_progress_tasks;
drop policy if exists self_write on public.narro_progress_tasks;
drop policy if exists self_update on public.narro_progress_tasks;
drop policy if exists self_delete on public.narro_progress_tasks;
create policy self_read on public.narro_progress_tasks for select to authenticated
  using (profile_id = auth.uid() or public.narro_current_role() in ('admin','super_admin'));
create policy self_write on public.narro_progress_tasks for insert to authenticated
  with check (profile_id = auth.uid());
create policy self_update on public.narro_progress_tasks for update to authenticated
  using (profile_id = auth.uid()) with check (profile_id = auth.uid());
create policy self_delete on public.narro_progress_tasks for delete to authenticated
  using (profile_id = auth.uid());

-- Function to seed the default 90-day plan for a profile
create or replace function public.narro_seed_progress_plan(p_profile_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.narro_progress_tasks where profile_id = p_profile_id;
  insert into public.narro_progress_tasks (profile_id, month_index, ordinal, title) values
    (p_profile_id, 1, 0, 'Réagir à une actualité de votre secteur'),
    (p_profile_id, 1, 1, 'Commenter une tendance émergente'),
    (p_profile_id, 1, 2, 'Partager un apprentissage simple'),
    (p_profile_id, 1, 3, 'Installer un rythme : 1 post / semaine'),
    (p_profile_id, 2, 0, 'Analyse marché : poser un point de vue'),
    (p_profile_id, 2, 1, 'Retour d''expérience sur un projet récent'),
    (p_profile_id, 2, 2, 'Décrypter un sujet sectoriel'),
    (p_profile_id, 2, 3, 'Passer à 2 posts / semaine'),
    (p_profile_id, 3, 0, 'Opinion personnelle assumée sur un sujet clivant'),
    (p_profile_id, 3, 1, 'Leadership sectoriel : proposer une vision'),
    (p_profile_id, 3, 2, 'Vision long terme : raconter votre cap'),
    (p_profile_id, 3, 3, 'Tenir 2-3 posts / semaine');
end$$;
revoke all on function public.narro_seed_progress_plan(uuid) from public;
grant execute on function public.narro_seed_progress_plan(uuid) to authenticated;

-- =========================
-- 6) Public holidays (used by calendar view; seeded for FR/BE/CH for 2026)
-- =========================
create table if not exists public.narro_holidays (
  id uuid primary key default gen_random_uuid(),
  country_code text not null,
  date date not null,
  label text not null
);
create unique index if not exists narro_holidays_unique on public.narro_holidays(country_code, date);
alter table public.narro_holidays enable row level security;
drop policy if exists read_all on public.narro_holidays;
create policy read_all on public.narro_holidays for select to anon, authenticated using (true);

-- Seed FR 2026
insert into public.narro_holidays (country_code, date, label) values
  ('FR', '2026-01-01', 'Jour de l''An'),
  ('FR', '2026-04-06', 'Lundi de Pâques'),
  ('FR', '2026-05-01', 'Fête du Travail'),
  ('FR', '2026-05-08', 'Victoire 1945'),
  ('FR', '2026-05-14', 'Ascension'),
  ('FR', '2026-05-25', 'Lundi de Pentecôte'),
  ('FR', '2026-07-14', 'Fête Nationale'),
  ('FR', '2026-08-15', 'Assomption'),
  ('FR', '2026-11-01', 'Toussaint'),
  ('FR', '2026-11-11', 'Armistice'),
  ('FR', '2026-12-25', 'Noël')
on conflict (country_code, date) do nothing;

insert into public.narro_holidays (country_code, date, label) values
  ('BE', '2026-01-01', 'Nouvel An'),
  ('BE', '2026-04-06', 'Lundi de Pâques'),
  ('BE', '2026-05-01', 'Fête du Travail'),
  ('BE', '2026-05-14', 'Ascension'),
  ('BE', '2026-07-21', 'Fête Nationale'),
  ('BE', '2026-08-15', 'Assomption'),
  ('BE', '2026-11-01', 'Toussaint'),
  ('BE', '2026-11-11', 'Armistice'),
  ('BE', '2026-12-25', 'Noël')
on conflict (country_code, date) do nothing;

-- =========================
-- 7) Trigger : when a profile is created, also seed its 90-day plan
-- =========================
create or replace function public.narro_after_profile_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.narro_seed_progress_plan(new.id);
  return new;
end$$;

drop trigger if exists narro_on_profile_insert on public.narro_profiles;
create trigger narro_on_profile_insert
  after insert on public.narro_profiles
  for each row execute function public.narro_after_profile_insert();

-- Backfill : seed plan for existing profiles that have none yet
do $$
declare
  p record;
begin
  for p in select id from public.narro_profiles loop
    if not exists (select 1 from public.narro_progress_tasks where profile_id = p.id) then
      perform public.narro_seed_progress_plan(p.id);
    end if;
  end loop;
end$$;

-- =========================
-- 8) Demo data clone : copy the demo profile's content into the caller's profile
-- =========================
create or replace function public.narro_import_demo()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  demo uuid := '00000000-0000-0000-0000-000000000001';
  me   uuid := auth.uid();
begin
  if me is null then
    raise exception 'not authenticated';
  end if;

  -- Keywords
  insert into public.narro_keywords (profile_id, label)
  select me, label from public.narro_keywords where profile_id = demo
  on conflict do nothing;

  -- Tracked influencers
  insert into public.narro_tracked_influencers (profile_id, handle, tag, profile_url)
  select me, handle, tag, profile_url from public.narro_tracked_influencers where profile_id = demo
  on conflict do nothing;

  -- Suggested posts (new ids to avoid clash with demo profile)
  insert into public.narro_suggested_posts
    (id, profile_id, week_offset, type, category, date_label, text, visual_type, title, posture, angle, status, ordinal, pertinence_scores, exposure_level)
  select id || '-' || substr(me::text, 1, 8), me, week_offset, type, category, date_label, text, visual_type, title, posture, angle, status, ordinal, pertinence_scores, exposure_level
  from public.narro_suggested_posts where profile_id = demo
  on conflict do nothing;

  -- News sources
  insert into public.narro_news_sources
    (id, profile_id, week_offset, category, title, origin, logo, url, ordinal)
  select id || '-' || substr(me::text, 1, 8), me, week_offset, category, title, origin, logo, url, ordinal
  from public.narro_news_sources where profile_id = demo
  on conflict do nothing;

  -- Network influences
  insert into public.narro_network_influences
    (id, profile_id, week_offset, user_handle, tag, text, logo, url, ordinal)
  select id || '-' || substr(me::text, 1, 8), me, week_offset, user_handle, tag, text, logo, url, ordinal
  from public.narro_network_influences where profile_id = demo
  on conflict do nothing;

  -- Events
  insert into public.narro_events (profile_id, title, description, suggested_text, event_date, event_type, status)
  select me, title, description, suggested_text, event_date, event_type, status
  from public.narro_events where profile_id = demo;

  -- Published posts
  insert into public.narro_published_posts
    (profile_id, title, content, posture, angle, status, published_at, like_count, share_count, comment_count, reach_count)
  select me, title, content, posture, angle, status, published_at, 12, 3, 5, 800
  from public.narro_published_posts where profile_id = demo;

  -- Mark profile onboarded with sample defaults
  update public.narro_profiles
    set sector = coalesce(sector, 'SaaS B2B'),
        target_audience = coalesce(target_audience, 'Dirigeants & RH'),
        primary_objective = coalesce(primary_objective, 'Renforcer ma crédibilité sectorielle'),
        tone_preset = coalesce(tone_preset, 'expert'),
        editorial_user_tag = coalesce(editorial_user_tag, '@MarcSimon'),
        onboarded = true,
        updated_at = now()
    where id = me;
end$$;
revoke all on function public.narro_import_demo() from public;
grant execute on function public.narro_import_demo() to authenticated;

-- =========================
-- 9) Teams (skeleton, prep pour offre Team — pas branché en UI)
-- =========================
create table if not exists public.narro_teams (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid not null references public.narro_profiles(id) on delete cascade,
  charter text default '',
  created_at timestamptz not null default now()
);
alter table public.narro_profiles
  add column if not exists team_id uuid references public.narro_teams(id) on delete set null;

alter table public.narro_teams enable row level security;
drop policy if exists members_read on public.narro_teams;
drop policy if exists owner_write on public.narro_teams;
create policy members_read on public.narro_teams for select to authenticated
  using (
    owner_id = auth.uid()
    or exists (select 1 from public.narro_profiles where id = auth.uid() and team_id = public.narro_teams.id)
    or public.narro_current_role() in ('admin','super_admin')
  );
create policy owner_write on public.narro_teams for all to authenticated
  using (owner_id = auth.uid() or public.narro_current_role() = 'super_admin')
  with check (owner_id = auth.uid() or public.narro_current_role() = 'super_admin');
