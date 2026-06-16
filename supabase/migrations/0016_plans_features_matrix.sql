-- 0016_plans_features_matrix.sql
-- Catalogue d'offres + features + matrice. Le super-admin pilote tout
-- depuis /super-admin/plans : nom des offres, liste de features par
-- page, matrice (offre x feature = enabled true/false).
-- 2026-06-15

-- 1) Plans : drop the legacy CHECK constraint so new tiers (Audit profil,
--    Planif post...) sont possibles sans nouvelle migration.
do $$
declare
  c text;
begin
  for c in
    select conname
    from pg_constraint
    where conrelid = 'public.narro_profiles'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) like '%subscription_tier%'
  loop
    execute format('alter table public.narro_profiles drop constraint %I', c);
  end loop;
end$$;

create table if not exists public.narro_plans (
  key                text primary key,                  -- machine slug
  label              text not null,                     -- display name
  description        text,
  price_eur_monthly  numeric(10,2),                     -- null = "Sur devis"
  oneshot            boolean not null default false,
  display_order      integer not null default 0,
  is_visible         boolean not null default true,     -- visible sur la page Pricing
  is_active          boolean not null default true,     -- selectionnable
  highlight          boolean not null default false,    -- mise en avant (badge "Le plus pris" par ex.)
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

create table if not exists public.narro_features (
  key             text primary key,                     -- machine slug (ex : "calendrier.view")
  page_key        text not null,                        -- group pour la matrice (ex : "calendrier")
  page_label      text not null,                        -- ex : "Calendrier"
  label           text not null,                        -- ex : "Voir la page"
  description     text,
  display_order   integer not null default 0,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists narro_features_page_idx
  on public.narro_features (page_key, display_order);

create table if not exists public.narro_plan_features (
  plan_key    text not null references public.narro_plans(key) on delete cascade,
  feature_key text not null references public.narro_features(key) on delete cascade,
  enabled     boolean not null default false,
  updated_at  timestamptz not null default now(),
  primary key (plan_key, feature_key)
);

-- 2) RLS
alter table public.narro_plans          enable row level security;
alter table public.narro_features       enable row level security;
alter table public.narro_plan_features  enable row level security;

drop policy if exists "plans select all"    on public.narro_plans;
drop policy if exists "plans super_admin"   on public.narro_plans;
drop policy if exists "features select all" on public.narro_features;
drop policy if exists "features super_admin" on public.narro_features;
drop policy if exists "plan_features select all" on public.narro_plan_features;
drop policy if exists "plan_features super_admin" on public.narro_plan_features;

create policy "plans select all"
  on public.narro_plans for select to authenticated using (true);

create policy "plans super_admin"
  on public.narro_plans for all to authenticated
  using (public.narro_current_role() = 'super_admin')
  with check (public.narro_current_role() = 'super_admin');

create policy "features select all"
  on public.narro_features for select to authenticated using (true);

create policy "features super_admin"
  on public.narro_features for all to authenticated
  using (public.narro_current_role() = 'super_admin')
  with check (public.narro_current_role() = 'super_admin');

create policy "plan_features select all"
  on public.narro_plan_features for select to authenticated using (true);

create policy "plan_features super_admin"
  on public.narro_plan_features for all to authenticated
  using (public.narro_current_role() = 'super_admin')
  with check (public.narro_current_role() = 'super_admin');

-- 3) Seed plans (5 existants + 2 nouveaux)
insert into public.narro_plans (key, label, description, price_eur_monthly, oneshot, display_order, is_visible, highlight)
values
  ('free',          'Free',             'Découverte gratuite',                            0,    false, 10, true,  false),
  ('solo',          'Solo',             'Dirigeant ou expert indépendant',                19,   false, 20, true,  false),
  ('pro',           'Pro',              'Avec validation équipe',                         49,   false, 30, true,  true),
  ('team',          'Team',             'Multi-utilisateurs avancé',                      99,   false, 40, true,  false),
  ('enterprise',    'Enterprise',       'Sur devis, support dédié',                       null, false, 50, true,  false),
  ('planif_post',   'Planif post',      'Programmez vos prises de parole à l''avance',    29,   false, 60, true,  false),
  ('audit_profil',  'Audit profil',     'Diagnostic ponctuel de votre profil LinkedIn',   199,  true,  70, true,  false)
on conflict (key) do nothing;

-- 4) Seed features (groupées par page)
-- Format : (key, page_key, page_label, label, description, display_order)
insert into public.narro_features (key, page_key, page_label, label, description, display_order)
values
  -- Inspiration
  ('inspiration.view',           'inspiration',  'Inspiration',           'Voir la page',                          'Accès au radar d''opportunités hebdo', 10),
  ('inspiration.generate_ai',    'inspiration',  'Inspiration',           'Générer avec l''IA',                    'Bouton "Générer mes suggestions"',     20),
  ('inspiration.hot_topics',     'inspiration',  'Inspiration',           'Bloc Hot topics',                       'Sujets émergents IA',                  30),
  ('inspiration.weekly_digest',  'inspiration',  'Inspiration',           'Bloc Digest hebdo',                     'Synthèse veille hebdomadaire',         40),
  ('inspiration.validate',       'inspiration',  'Inspiration',           'Bouton Valider',                        'Envoi direct vers À valider',          50),

  -- Labo éditorial
  ('labo.view',                  'labo',         'Labo éditorial',        'Voir la page',                          'Croisement de signaux',                10),
  ('labo.build_angle',           'labo',         'Labo éditorial',        'Construire l''angle IA',                'Construction de l''angle Narro',       20),
  ('labo.push_to_rediger',       'labo',         'Labo éditorial',        'Envoyer vers Rédiger',                  'Pré-fill cross-page',                  30),

  -- Rédiger
  ('rediger.view',               'rediger',      'Rédiger',               'Voir la page',                          'Page de prise de parole',              10),
  ('rediger.generate_post',      'rediger',      'Rédiger',               'Générer un post IA',                    'Génération Claude',                    20),
  ('rediger.visual_narro',       'rediger',      'Rédiger',               'Visuel suggéré par Narro',              'Bloc Unsplash suggéré',                30),
  ('rediger.visual_upload',      'rediger',      'Rédiger',               'Importer un visuel',                    'Upload d''image utilisateur',          40),

  -- Calendrier
  ('calendrier.view',            'calendrier',   'Calendrier',            'Voir la page',                          'Vue calendrier mensuelle',             10),
  ('calendrier.alert_rythme',    'calendrier',   'Calendrier',            'Bandeau alerte rythme',                 'Alerte retard hebdo',                  20),
  ('calendrier.file_editoriale', 'calendrier',   'Calendrier',            'File éditoriale du mois',               'Tableau avec filtres et actions',      30),

  -- Temps forts
  ('tempsforts.view',            'tempsforts',   'Temps forts',           'Voir la page',                          'Radar d''opportunités événementielles', 10),
  ('tempsforts.discover_ai',     'tempsforts',   'Temps forts',           'Découverte IA (Perplexity)',            'Auto-discover des temps forts secteur', 20),
  ('tempsforts.add_manual',      'tempsforts',   'Temps forts',           'Ajouter manuellement',                  'Formulaire +Ajouter un temps fort',    30),
  ('tempsforts.marronniers',     'tempsforts',   'Temps forts',           'Bloc Marronniers',                      'Activer un marronnier sectoriel',      40),
  ('tempsforts.timeline',        'tempsforts',   'Temps forts',           'Timeline éditoriale',                   'Colonne droite + Narro suggestions',   50),

  -- Brouillons
  ('brouillons.view',            'brouillons',   'Brouillons',            'Voir la page',                          'Liste des brouillons',                 10),

  -- À valider
  ('avalider.view',              'avalider',     'À valider',             'Voir la page',                          'File d''approbation équipe',           10),
  ('avalider.publish',           'avalider',     'À valider',             'Publier sur LinkedIn',                  'Publication directe via API',          20),

  -- Performances
  ('performances.view',          'performances', 'Performances',          'Voir la page',                          'Analytics LinkedIn',                   10),

  -- Stratégie éditoriale
  ('strategie.view',             'strategie',    'Stratégie éditoriale',  'Voir la page',                          'Piliers éditoriaux',                   10),

  -- Bibliothèque de marque
  ('bibliotheque.view',          'bibliotheque', 'Bibliothèque de marque', 'Voir la page',                         'Voix, ton, formules récurrentes',      10),

  -- Paramètres & abonnement (toujours actif par défaut)
  ('params.view',                'params',       'Paramètres',            'Voir la page',                          'Compte, équipe, abonnement',           10),
  ('params.linkedin',            'params',       'Paramètres',            'Connexion LinkedIn',                    'OAuth LinkedIn',                       20),
  ('params.feeds',               'params',       'Paramètres',            'Gestion des flux RSS',                  'Ajout/suppression/refresh',            30),
  ('params.curated_sources',     'params',       'Paramètres',            'Bibliothèque sources curées',           'Sources pré-validées par secteur',     40),
  ('params.google_news',         'params',       'Paramètres',            'Quick add Google News',                 'Recherche Google News',                50),

  -- Widget feedback
  ('widget.feedback',            'widget',       'Widget feedback',       'Bouton flottant',                       'Capture + retour utilisateur',         10)
on conflict (key) do nothing;

-- 5) Seed matrice par défaut (qui aura quoi)
-- params.view et widget.feedback : activés pour TOUS les plans, toujours
-- Plans courants : on définit une montée en gamme classique
with all_plans as (select key from public.narro_plans),
universal_features as (
  select 'params.view'::text as key
  union all select 'params.linkedin'
  union all select 'widget.feedback'
)
insert into public.narro_plan_features (plan_key, feature_key, enabled)
select ap.key, uf.key, true
from all_plans ap cross join universal_features uf
on conflict (plan_key, feature_key) do nothing;

-- Free : Inspiration view, Labo view, Brouillons view, basic
insert into public.narro_plan_features (plan_key, feature_key, enabled)
values
  ('free', 'inspiration.view', true),
  ('free', 'labo.view',        true),
  ('free', 'rediger.view',     true),
  ('free', 'brouillons.view',  true)
on conflict (plan_key, feature_key) do nothing;

-- Solo : Free + IA + Calendar + Temps forts manual + Visuel Narro
insert into public.narro_plan_features (plan_key, feature_key, enabled)
values
  ('solo', 'inspiration.view',          true),
  ('solo', 'inspiration.generate_ai',   true),
  ('solo', 'inspiration.hot_topics',    true),
  ('solo', 'inspiration.weekly_digest', true),
  ('solo', 'inspiration.validate',      true),
  ('solo', 'labo.view',                 true),
  ('solo', 'labo.build_angle',          true),
  ('solo', 'labo.push_to_rediger',      true),
  ('solo', 'rediger.view',              true),
  ('solo', 'rediger.generate_post',     true),
  ('solo', 'rediger.visual_narro',      true),
  ('solo', 'rediger.visual_upload',     true),
  ('solo', 'calendrier.view',           true),
  ('solo', 'calendrier.alert_rythme',   true),
  ('solo', 'calendrier.file_editoriale',true),
  ('solo', 'tempsforts.view',           true),
  ('solo', 'tempsforts.add_manual',     true),
  ('solo', 'tempsforts.marronniers',    true),
  ('solo', 'tempsforts.timeline',       true),
  ('solo', 'brouillons.view',           true),
  ('solo', 'performances.view',         true),
  ('solo', 'strategie.view',            true),
  ('solo', 'bibliotheque.view',         true),
  ('solo', 'params.feeds',              true),
  ('solo', 'params.curated_sources',    true),
  ('solo', 'params.google_news',        true)
on conflict (plan_key, feature_key) do nothing;

-- Pro : Solo + Validation équipe + Discover IA + LinkedIn publish
insert into public.narro_plan_features (plan_key, feature_key, enabled)
select 'pro', key, true from public.narro_features
where key in (
  'inspiration.view','inspiration.generate_ai','inspiration.hot_topics','inspiration.weekly_digest','inspiration.validate',
  'labo.view','labo.build_angle','labo.push_to_rediger',
  'rediger.view','rediger.generate_post','rediger.visual_narro','rediger.visual_upload',
  'calendrier.view','calendrier.alert_rythme','calendrier.file_editoriale',
  'tempsforts.view','tempsforts.discover_ai','tempsforts.add_manual','tempsforts.marronniers','tempsforts.timeline',
  'brouillons.view','avalider.view','avalider.publish',
  'performances.view','strategie.view','bibliotheque.view',
  'params.feeds','params.curated_sources','params.google_news'
)
on conflict (plan_key, feature_key) do nothing;

-- Team / Enterprise : tout activé
insert into public.narro_plan_features (plan_key, feature_key, enabled)
select 'team', key, true from public.narro_features
on conflict (plan_key, feature_key) do nothing;

insert into public.narro_plan_features (plan_key, feature_key, enabled)
select 'enterprise', key, true from public.narro_features
on conflict (plan_key, feature_key) do nothing;

-- Planif post : sous-ensemble centré planification + publication
insert into public.narro_plan_features (plan_key, feature_key, enabled)
values
  ('planif_post', 'rediger.view',           true),
  ('planif_post', 'rediger.generate_post',  true),
  ('planif_post', 'calendrier.view',        true),
  ('planif_post', 'calendrier.file_editoriale', true),
  ('planif_post', 'brouillons.view',        true),
  ('planif_post', 'avalider.view',          true),
  ('planif_post', 'avalider.publish',       true),
  ('planif_post', 'params.feeds',           true)
on conflict (plan_key, feature_key) do nothing;

-- Audit profil : oneshot — accès lecture Inspiration + Bibliothèque + Paramètres
insert into public.narro_plan_features (plan_key, feature_key, enabled)
values
  ('audit_profil', 'inspiration.view',  true),
  ('audit_profil', 'bibliotheque.view', true),
  ('audit_profil', 'strategie.view',    true),
  ('audit_profil', 'params.feeds',      true)
on conflict (plan_key, feature_key) do nothing;
