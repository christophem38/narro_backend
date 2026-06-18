-- 0019_brand_library_strategy.sql
-- Stratégie éditoriale + Bibliothèque de marque + cadrage de génération.
-- Cf. Narro_Specs_Dev (2).docx.
-- 2026-06-18

-- =============================================================
-- 1. Stratégie éditoriale (singleton par profil)
-- =============================================================
create table if not exists public.narro_editorial_strategy (
  profile_id              uuid primary key references public.narro_profiles(id) on delete cascade,
  -- Cap stratégique (formulaire minimal)
  primary_objective       text,
  primary_audience        text,
  weekly_rhythm           smallint check (weekly_rhythm between 0 and 7),
  -- Cap détaillé
  vision_3y               text,
  positioning             text,
  reputation_signals      text[]  default '{}',
  -- Piliers, audiences détaillées, équilibre (jsonb pour évoluer librement)
  pillars                 jsonb   not null default '[]'::jsonb,
  audiences               jsonb   not null default '[]'::jsonb,
  balance_targets         jsonb   not null default '{}'::jsonb,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

alter table public.narro_editorial_strategy enable row level security;
drop policy if exists editorial_self on public.narro_editorial_strategy;
create policy editorial_self on public.narro_editorial_strategy
  for all to authenticated
  using (profile_id = auth.uid()
         or public.narro_current_role() in ('admin','super_admin'))
  with check (profile_id = auth.uid()
              or public.narro_current_role() in ('admin','super_admin'));

-- =============================================================
-- 2. Bibliothèque de marque — voix (singleton)
-- =============================================================
create table if not exists public.narro_brand_voice (
  profile_id          uuid primary key references public.narro_profiles(id) on delete cascade,
  -- Formulaire minimal
  posture             text,
  avoided_tones       text[] default '{}',
  -- Champs étendus (onglet Voix)
  recommended_tone    text,
  embodiment_level    text check (embodiment_level in ('faible','equilibre','fort')),
  writing_style       text,
  to_avoid            text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

alter table public.narro_brand_voice enable row level security;
drop policy if exists brand_voice_self on public.narro_brand_voice;
create policy brand_voice_self on public.narro_brand_voice
  for all to authenticated
  using (profile_id = auth.uid()
         or public.narro_current_role() in ('admin','super_admin'))
  with check (profile_id = auth.uid()
              or public.narro_current_role() in ('admin','super_admin'));

-- =============================================================
-- 3. Territoires éditoriaux
-- =============================================================
create table if not exists public.narro_brand_territories (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid not null references public.narro_profiles(id) on delete cascade,
  name        text not null,
  angle       text,
  display_order integer not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index if not exists brand_territories_profile_idx
  on public.narro_brand_territories (profile_id, display_order);

alter table public.narro_brand_territories enable row level security;
drop policy if exists territories_self on public.narro_brand_territories;
create policy territories_self on public.narro_brand_territories
  for all to authenticated
  using (profile_id = auth.uid()
         or public.narro_current_role() in ('admin','super_admin'))
  with check (profile_id = auth.uid()
              or public.narro_current_role() in ('admin','super_admin'));

-- =============================================================
-- 4. Messages clés
-- =============================================================
create table if not exists public.narro_brand_key_messages (
  id                  uuid primary key default gen_random_uuid(),
  profile_id          uuid not null references public.narro_profiles(id) on delete cascade,
  message             text not null,
  proof               text,
  recommended_phrase  text,
  avoid_phrase        text,
  audience            text,
  display_order       integer not null default 0,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);
create index if not exists brand_key_messages_profile_idx
  on public.narro_brand_key_messages (profile_id, display_order);

alter table public.narro_brand_key_messages enable row level security;
drop policy if exists key_messages_self on public.narro_brand_key_messages;
create policy key_messages_self on public.narro_brand_key_messages
  for all to authenticated
  using (profile_id = auth.uid()
         or public.narro_current_role() in ('admin','super_admin'))
  with check (profile_id = auth.uid()
              or public.narro_current_role() in ('admin','super_admin'));

-- =============================================================
-- 5. Preuves & références
-- =============================================================
create table if not exists public.narro_brand_evidences (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid not null references public.narro_profiles(id) on delete cascade,
  kind        text not null check (kind in (
                'chiffre','etude','cas_client','citation','exemple_interne',
                'retour_terrain','evenement','lien','post_linkedin','autre')),
  label       text not null,
  description text,
  link        text,
  display_order integer not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index if not exists brand_evidences_profile_idx
  on public.narro_brand_evidences (profile_id, kind, display_order);

alter table public.narro_brand_evidences enable row level security;
drop policy if exists evidences_self on public.narro_brand_evidences;
create policy evidences_self on public.narro_brand_evidences
  for all to authenticated
  using (profile_id = auth.uid()
         or public.narro_current_role() in ('admin','super_admin'))
  with check (profile_id = auth.uid()
              or public.narro_current_role() in ('admin','super_admin'));

-- =============================================================
-- 6. Garde-fous éditoriaux
-- =============================================================
create table if not exists public.narro_brand_guardrails (
  id              uuid primary key default gen_random_uuid(),
  profile_id      uuid not null references public.narro_profiles(id) on delete cascade,
  sensitive_topic text not null,
  rule            text not null,
  required_validation text,
  risk_level      text check (risk_level in ('low','medium','high')) default 'medium',
  trigger_phrases text[] default '{}',
  display_order   integer not null default 0,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index if not exists brand_guardrails_profile_idx
  on public.narro_brand_guardrails (profile_id, display_order);

alter table public.narro_brand_guardrails enable row level security;
drop policy if exists guardrails_self on public.narro_brand_guardrails;
create policy guardrails_self on public.narro_brand_guardrails
  for all to authenticated
  using (profile_id = auth.uid()
         or public.narro_current_role() in ('admin','super_admin'))
  with check (profile_id = auth.uid()
              or public.narro_current_role() in ('admin','super_admin'));

-- =============================================================
-- 7. Éléments de langage
-- =============================================================
create table if not exists public.narro_brand_language_elements (
  id            uuid primary key default gen_random_uuid(),
  profile_id    uuid not null references public.narro_profiles(id) on delete cascade,
  category      text not null check (category in (
                  'accroche','transition','conclusion','cta',
                  'expression_dirigeant','vocabulaire_metier','hashtag',
                  'a_eviter','juridique_sensible','autre')),
  phrase        text not null,
  note          text,
  display_order integer not null default 0,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index if not exists brand_language_profile_idx
  on public.narro_brand_language_elements (profile_id, category, display_order);

alter table public.narro_brand_language_elements enable row level security;
drop policy if exists language_elements_self on public.narro_brand_language_elements;
create policy language_elements_self on public.narro_brand_language_elements
  for all to authenticated
  using (profile_id = auth.uid()
         or public.narro_current_role() in ('admin','super_admin'))
  with check (profile_id = auth.uid()
              or public.narro_current_role() in ('admin','super_admin'));

-- =============================================================
-- 8. Helper completude (utilisable côté code, mais on calcule en TS)
-- =============================================================
create or replace function public.narro_brand_completude(p_profile uuid)
returns numeric
language sql
stable
as $$
  with parts as (
    select 0.20 as weight, case when exists (
      select 1 from public.narro_brand_voice v where v.profile_id = p_profile
        and (v.posture is not null or v.recommended_tone is not null)
    ) then 1 else 0 end as score
    union all
    select 0.20, case when exists (
      select 1 from public.narro_brand_territories where profile_id = p_profile limit 1
    ) then 1 else 0 end
    union all
    select 0.20, case when exists (
      select 1 from public.narro_brand_key_messages where profile_id = p_profile limit 1
    ) then 1 else 0 end
    union all
    select 0.20, case when exists (
      select 1 from public.narro_brand_evidences where profile_id = p_profile limit 1
    ) then 1 else 0 end
    union all
    select 0.20, case when exists (
      select 1 from public.narro_brand_guardrails where profile_id = p_profile limit 1
    ) then 1 else 0 end
  )
  select coalesce(sum(weight * score), 0) from parts;
$$;
