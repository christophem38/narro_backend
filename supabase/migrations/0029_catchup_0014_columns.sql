-- 0029 : rattrapage des COLONNES manquantes (migration 0014 jamais appliquée)
--
-- 0014 ajoutait des colonnes à suggested_posts et events + créait marronniers.
-- 0028 avait recréé la table marronniers mais PAS ces colonnes -> le bouton
-- « Rédiger » du Labo (insert avec `intention`) plantait en Server Component.
-- On ajoute aussi source_title (0012) et la contrainte de statut (0012) en
-- filet, au cas où ces migrations n'auraient pas tourné non plus.
-- Idempotent : add column if not exists.

-- profiles : cadence mensuelle (lue avec fallback ?? 8 côté code, mais on l'aligne)
alter table public.elocia_profiles
  add column if not exists monthly_target smallint not null default 8;

-- suggested_posts : colonnes 0014 + source_title (0012, filet)
alter table public.elocia_suggested_posts
  add column if not exists scheduled_for timestamptz,
  add column if not exists approved_at   timestamptz,
  add column if not exists intention     text,
  add column if not exists source_title  text;

create index if not exists elocia_suggested_posts_scheduled_for_idx
  on public.elocia_suggested_posts (profile_id, scheduled_for)
  where scheduled_for is not null;

-- Statut : autoriser 'awaiting_validation' (0012). La contrainte garde son nom
-- d'origine narro_* (un rename de table ne renomme pas les contraintes).
do $$
begin
  if exists (select 1 from pg_constraint where conname = 'narro_suggested_posts_status_check') then
    alter table public.elocia_suggested_posts drop constraint narro_suggested_posts_status_check;
  end if;
  if exists (select 1 from pg_constraint where conname = 'elocia_suggested_posts_status_check') then
    alter table public.elocia_suggested_posts drop constraint elocia_suggested_posts_status_check;
  end if;
  alter table public.elocia_suggested_posts
    add constraint elocia_suggested_posts_status_check
    check (status in ('draft','awaiting_validation','published','expired'));
end$$;

-- events : enrichissement 0014 (noms de colonnes conservés tels quels, dont
-- narro_pertinence / narro_angle : un rename de table ne renomme pas les colonnes)
alter table public.elocia_events
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

create index if not exists elocia_events_source_tag_idx  on public.elocia_events (profile_id, source_tag);
create index if not exists elocia_events_event_date_idx  on public.elocia_events (profile_id, event_date);
