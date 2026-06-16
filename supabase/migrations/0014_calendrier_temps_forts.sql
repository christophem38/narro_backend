-- 0014_calendrier_temps_forts.sql
-- Refonte Calendrier + Temps forts selon Narro_Specs_Dev (1).docx
-- 2026-06-15

-- 1) Cadences éditoriales (Calendrier : bandeau alerte + cartes pilotage)
alter table public.narro_profiles
  add column if not exists weekly_target  smallint not null default 2,
  add column if not exists monthly_target smallint not null default 8;

-- 2) Statuts unifiés posts : draft / awaiting_validation / approved / scheduled / published
-- (déjà existants : draft / awaiting_validation. on ajoute scheduled_for + approved_at.)
alter table public.narro_suggested_posts
  add column if not exists scheduled_for timestamptz,
  add column if not exists approved_at   timestamptz,
  add column if not exists intention     text;

create index if not exists narro_suggested_posts_scheduled_for_idx
  on public.narro_suggested_posts (profile_id, scheduled_for)
  where scheduled_for is not null;

-- 3) Temps forts : enrichissement des évènements
-- Distinction source (narro_detected / user_added / marronnier), rôle, objectifs,
-- audience, niveau de priorité, lien interne, confidentialité.
alter table public.narro_events
  add column if not exists source_tag        text default 'user_added'
    check (source_tag in ('user_added', 'narro_detected', 'marronnier')),
  add column if not exists priority_level    text default 'normal'
    check (priority_level in ('high', 'normal', 'low')),
  add column if not exists user_role         text,
  add column if not exists objective_tags    text[] default '{}',
  add column if not exists audience_tags     text[] default '{}',
  add column if not exists internal_link     text,
  add column if not exists internal_note     text,
  add column if not exists is_private        boolean not null default false,
  add column if not exists narro_pertinence  text,
  add column if not exists narro_angle       text,
  add column if not exists theme_tag         text,
  add column if not exists debrief_published boolean not null default false,
  add column if not exists ignored_until     date;

create index if not exists narro_events_source_tag_idx
  on public.narro_events (profile_id, source_tag);

create index if not exists narro_events_event_date_idx
  on public.narro_events (profile_id, event_date);

-- 4) Marronniers sectoriels : table dédiée
-- Une ligne par marronnier disponible pour un secteur. L'utilisateur clique
-- sur "Activer" pour le matérialiser dans narro_events.
create table if not exists public.narro_marronniers (
  id          uuid primary key default gen_random_uuid(),
  sector      text not null,
  label       text not null,
  start_date  date not null,
  end_date    date,
  description text,
  created_at  timestamptz not null default now()
);

create index if not exists narro_marronniers_sector_idx
  on public.narro_marronniers (sector, start_date);

alter table public.narro_marronniers enable row level security;

drop policy if exists "narro_marronniers select all" on public.narro_marronniers;
create policy "narro_marronniers select all"
  on public.narro_marronniers
  for select
  to authenticated
  using (true);

-- 5) Seed minimal de marronniers universels
insert into public.narro_marronniers (sector, label, start_date, description)
values
  ('*', 'Rentrée stratégique', '2026-09-01',
    'Le retour de septembre : moment fort pour cadrer la dynamique du dernier trimestre.'),
  ('*', 'Bilan fin d''année', '2026-12-15',
    'Capitaliser sur les enseignements de l''année et poser les ambitions de la suivante.'),
  ('*', 'Budget annuel', '2026-11-01',
    'Période de cadrage budgétaire : occasion de partager une vision sur les arbitrages stratégiques.'),
  ('*', 'Bilan S1', '2026-07-01',
    'Le moment idéal pour partager 3 enseignements clés du premier semestre.')
on conflict do nothing;
