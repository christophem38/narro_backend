-- 0028 : rattrapage des tables jamais créées en base (elocia_*)
--
-- Diagnostic : ces tables sont référencées par le code mais absentes en base
-- (migrations 0014 marronniers, 0015 user_feedback, 0016 plans/features
-- jamais appliquées). Recréées ici directement sous le nom elocia_*, avec
-- FK/index/RLS, et libellés déjà en « Elocia » (fusion de 0025).
-- Idempotente : create table if not exists + on conflict do nothing.

-- =========================================================
-- 1) Retours utilisateur (ex-migration 0015)
-- =========================================================
create table if not exists public.elocia_user_feedback (
  id              uuid primary key default gen_random_uuid(),
  profile_id      uuid not null references public.elocia_profiles(id) on delete cascade,
  page_path       text not null,
  page_title      text,
  user_agent      text,
  viewport        text,
  message         text not null,
  screenshot_path text,
  attachment_path text,
  attachment_name text,
  attachment_type text,
  status          text not null default 'open'
    check (status in ('open', 'in_progress', 'resolved', 'wontfix')),
  admin_note      text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists elocia_user_feedback_profile_idx
  on public.elocia_user_feedback (profile_id, created_at desc);
create index if not exists elocia_user_feedback_status_idx
  on public.elocia_user_feedback (status, created_at desc);

alter table public.elocia_user_feedback enable row level security;

drop policy if exists "feedback user insert own" on public.elocia_user_feedback;
create policy "feedback user insert own" on public.elocia_user_feedback
  for insert to authenticated with check (profile_id = auth.uid());

drop policy if exists "feedback select own or admin" on public.elocia_user_feedback;
create policy "feedback select own or admin" on public.elocia_user_feedback
  for select to authenticated
  using (profile_id = auth.uid() or public.narro_current_role() in ('admin', 'super_admin'));

drop policy if exists "feedback admin update" on public.elocia_user_feedback;
create policy "feedback admin update" on public.elocia_user_feedback
  for update to authenticated
  using (public.narro_current_role() in ('admin', 'super_admin'))
  with check (public.narro_current_role() in ('admin', 'super_admin'));

drop policy if exists "feedback admin delete" on public.elocia_user_feedback;
create policy "feedback admin delete" on public.elocia_user_feedback
  for delete to authenticated
  using (public.narro_current_role() in ('admin', 'super_admin'));

-- Bucket privé (le code écrit toujours dans "narro-feedback", on garde ce nom)
insert into storage.buckets (id, name, public, file_size_limit)
values ('narro-feedback', 'narro-feedback', false, 5242880)
on conflict (id) do update set file_size_limit = excluded.file_size_limit;

drop policy if exists "feedback storage user insert" on storage.objects;
create policy "feedback storage user insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'narro-feedback' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "feedback storage user read" on storage.objects;
create policy "feedback storage user read" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'narro-feedback'
    and ((storage.foldername(name))[1] = auth.uid()::text
         or public.narro_current_role() in ('admin', 'super_admin'))
  );

-- =========================================================
-- 2) Marronniers (ex-migration 0014)
-- =========================================================
create table if not exists public.elocia_marronniers (
  id          uuid primary key default gen_random_uuid(),
  sector      text not null,
  label       text not null,
  start_date  date not null,
  end_date    date,
  description text,
  created_at  timestamptz not null default now()
);

create index if not exists elocia_marronniers_sector_idx
  on public.elocia_marronniers (sector, start_date);

alter table public.elocia_marronniers enable row level security;

drop policy if exists "marronniers select all" on public.elocia_marronniers;
create policy "marronniers select all" on public.elocia_marronniers
  for select to authenticated using (true);

insert into public.elocia_marronniers (sector, label, start_date, description)
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

-- =========================================================
-- 3) Matrice plans / features (ex-migration 0016, libellés Elocia)
-- =========================================================
create table if not exists public.elocia_plans (
  key                text primary key,
  label              text not null,
  description        text,
  price_eur_monthly  numeric(10,2),
  oneshot            boolean not null default false,
  display_order      integer not null default 0,
  is_visible         boolean not null default true,
  is_active          boolean not null default true,
  highlight          boolean not null default false,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

create table if not exists public.elocia_features (
  key             text primary key,
  page_key        text not null,
  page_label      text not null,
  label           text not null,
  description     text,
  display_order   integer not null default 0,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index if not exists elocia_features_page_idx
  on public.elocia_features (page_key, display_order);

create table if not exists public.elocia_plan_features (
  plan_key    text not null references public.elocia_plans(key) on delete cascade,
  feature_key text not null references public.elocia_features(key) on delete cascade,
  enabled     boolean not null default false,
  updated_at  timestamptz not null default now(),
  primary key (plan_key, feature_key)
);

alter table public.elocia_plans         enable row level security;
alter table public.elocia_features      enable row level security;
alter table public.elocia_plan_features enable row level security;

drop policy if exists "plans select all"          on public.elocia_plans;
drop policy if exists "plans super_admin"          on public.elocia_plans;
drop policy if exists "features select all"        on public.elocia_features;
drop policy if exists "features super_admin"       on public.elocia_features;
drop policy if exists "plan_features select all"   on public.elocia_plan_features;
drop policy if exists "plan_features super_admin"  on public.elocia_plan_features;

create policy "plans select all"   on public.elocia_plans for select to authenticated using (true);
create policy "plans super_admin"  on public.elocia_plans for all to authenticated
  using (public.narro_current_role() = 'super_admin') with check (public.narro_current_role() = 'super_admin');
create policy "features select all"  on public.elocia_features for select to authenticated using (true);
create policy "features super_admin" on public.elocia_features for all to authenticated
  using (public.narro_current_role() = 'super_admin') with check (public.narro_current_role() = 'super_admin');
create policy "plan_features select all"  on public.elocia_plan_features for select to authenticated using (true);
create policy "plan_features super_admin" on public.elocia_plan_features for all to authenticated
  using (public.narro_current_role() = 'super_admin') with check (public.narro_current_role() = 'super_admin');

insert into public.elocia_plans (key, label, description, price_eur_monthly, oneshot, display_order, is_visible, highlight)
values
  ('free',         'Free',         'Découverte gratuite',                          0,    false, 10, true,  false),
  ('solo',         'Solo',         'Dirigeant ou expert indépendant',              19,   false, 20, true,  false),
  ('pro',          'Pro',          'Avec validation équipe',                       49,   false, 30, true,  true),
  ('team',         'Team',         'Multi-utilisateurs avancé',                    99,   false, 40, true,  false),
  ('enterprise',   'Enterprise',   'Sur devis, support dédié',                     null, false, 50, true,  false),
  ('planif_post',  'Planif post',  'Programmez vos prises de parole à l''avance',  29,   false, 60, true,  false),
  ('audit_profil', 'Audit profil', 'Diagnostic ponctuel de votre profil LinkedIn', 199,  true,  70, true,  false)
on conflict (key) do nothing;

insert into public.elocia_features (key, page_key, page_label, label, description, display_order)
values
  ('inspiration.view',           'inspiration',  'Inspiration',            'Voir la page',              'Accès au radar d''opportunités hebdo', 10),
  ('inspiration.generate_ai',    'inspiration',  'Inspiration',            'Générer avec l''IA',        'Bouton "Générer mes suggestions"',     20),
  ('inspiration.hot_topics',     'inspiration',  'Inspiration',            'Bloc Hot topics',           'Sujets émergents IA',                  30),
  ('inspiration.weekly_digest',  'inspiration',  'Inspiration',            'Bloc Digest hebdo',         'Synthèse veille hebdomadaire',         40),
  ('inspiration.validate',       'inspiration',  'Inspiration',            'Bouton Valider',            'Envoi direct vers À valider',          50),
  ('labo.view',                  'labo',         'Labo éditorial',         'Voir la page',              'Croisement de signaux',                10),
  ('labo.build_angle',           'labo',         'Labo éditorial',         'Construire l''angle IA',    'Construction de l''angle Elocia',      20),
  ('labo.push_to_rediger',       'labo',         'Labo éditorial',         'Envoyer vers Rédiger',      'Pré-fill cross-page',                  30),
  ('rediger.view',               'rediger',      'Rédiger',                'Voir la page',              'Page de prise de parole',              10),
  ('rediger.generate_post',      'rediger',      'Rédiger',                'Générer un post IA',        'Génération Claude',                    20),
  ('rediger.visual_narro',       'rediger',      'Rédiger',                'Visuel suggéré par Elocia', 'Bloc Unsplash suggéré',                30),
  ('rediger.visual_upload',      'rediger',      'Rédiger',                'Importer un visuel',        'Upload d''image utilisateur',          40),
  ('calendrier.view',            'calendrier',   'Calendrier',             'Voir la page',              'Vue calendrier mensuelle',             10),
  ('calendrier.alert_rythme',    'calendrier',   'Calendrier',             'Bandeau alerte rythme',     'Alerte retard hebdo',                  20),
  ('calendrier.file_editoriale', 'calendrier',   'Calendrier',             'File éditoriale du mois',   'Tableau avec filtres et actions',      30),
  ('tempsforts.view',            'tempsforts',   'Temps forts',            'Voir la page',              'Radar d''opportunités événementielles', 10),
  ('tempsforts.discover_ai',     'tempsforts',   'Temps forts',            'Découverte IA (Perplexity)','Auto-discover des temps forts secteur', 20),
  ('tempsforts.add_manual',      'tempsforts',   'Temps forts',            'Ajouter manuellement',      'Formulaire +Ajouter un temps fort',    30),
  ('tempsforts.marronniers',     'tempsforts',   'Temps forts',            'Bloc Marronniers',          'Activer un marronnier sectoriel',      40),
  ('tempsforts.timeline',        'tempsforts',   'Temps forts',            'Timeline éditoriale',       'Colonne droite + Elocia suggestions',  50),
  ('brouillons.view',            'brouillons',   'Brouillons',             'Voir la page',              'Liste des brouillons',                 10),
  ('avalider.view',              'avalider',     'À valider',              'Voir la page',              'File d''approbation équipe',           10),
  ('avalider.publish',           'avalider',     'À valider',              'Publier sur LinkedIn',      'Publication directe via API',          20),
  ('performances.view',          'performances', 'Performances',           'Voir la page',              'Analytics LinkedIn',                   10),
  ('strategie.view',             'strategie',    'Stratégie éditoriale',   'Voir la page',              'Piliers éditoriaux',                   10),
  ('bibliotheque.view',          'bibliotheque', 'Bibliothèque de marque', 'Voir la page',              'Voix, ton, formules récurrentes',      10),
  ('params.view',                'params',       'Paramètres',             'Voir la page',              'Compte, équipe, abonnement',           10),
  ('params.linkedin',            'params',       'Paramètres',             'Connexion LinkedIn',        'OAuth LinkedIn',                       20),
  ('params.feeds',               'params',       'Paramètres',             'Gestion des flux RSS',      'Ajout/suppression/refresh',            30),
  ('params.curated_sources',     'params',       'Paramètres',             'Bibliothèque sources curées','Sources pré-validées par secteur',    40),
  ('params.google_news',         'params',       'Paramètres',             'Quick add Google News',     'Recherche Google News',                50),
  ('widget.feedback',            'widget',       'Widget feedback',        'Bouton flottant',           'Capture + retour utilisateur',         10)
on conflict (key) do nothing;

-- Matrice par défaut
with all_plans as (select key from public.elocia_plans),
universal_features as (
  select 'params.view'::text as key
  union all select 'params.linkedin'
  union all select 'widget.feedback'
)
insert into public.elocia_plan_features (plan_key, feature_key, enabled)
select ap.key, uf.key, true from all_plans ap cross join universal_features uf
on conflict (plan_key, feature_key) do nothing;

insert into public.elocia_plan_features (plan_key, feature_key, enabled)
values
  ('free', 'inspiration.view', true),
  ('free', 'labo.view',        true),
  ('free', 'rediger.view',     true),
  ('free', 'brouillons.view',  true)
on conflict (plan_key, feature_key) do nothing;

insert into public.elocia_plan_features (plan_key, feature_key, enabled)
values
  ('solo', 'inspiration.view', true), ('solo', 'inspiration.generate_ai', true),
  ('solo', 'inspiration.hot_topics', true), ('solo', 'inspiration.weekly_digest', true),
  ('solo', 'inspiration.validate', true), ('solo', 'labo.view', true),
  ('solo', 'labo.build_angle', true), ('solo', 'labo.push_to_rediger', true),
  ('solo', 'rediger.view', true), ('solo', 'rediger.generate_post', true),
  ('solo', 'rediger.visual_narro', true), ('solo', 'rediger.visual_upload', true),
  ('solo', 'calendrier.view', true), ('solo', 'calendrier.alert_rythme', true),
  ('solo', 'calendrier.file_editoriale', true), ('solo', 'tempsforts.view', true),
  ('solo', 'tempsforts.add_manual', true), ('solo', 'tempsforts.marronniers', true),
  ('solo', 'tempsforts.timeline', true), ('solo', 'brouillons.view', true),
  ('solo', 'performances.view', true), ('solo', 'strategie.view', true),
  ('solo', 'bibliotheque.view', true), ('solo', 'params.feeds', true),
  ('solo', 'params.curated_sources', true), ('solo', 'params.google_news', true)
on conflict (plan_key, feature_key) do nothing;

insert into public.elocia_plan_features (plan_key, feature_key, enabled)
select 'pro', key, true from public.elocia_features
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

insert into public.elocia_plan_features (plan_key, feature_key, enabled)
select 'team', key, true from public.elocia_features
on conflict (plan_key, feature_key) do nothing;

insert into public.elocia_plan_features (plan_key, feature_key, enabled)
select 'enterprise', key, true from public.elocia_features
on conflict (plan_key, feature_key) do nothing;

insert into public.elocia_plan_features (plan_key, feature_key, enabled)
values
  ('planif_post', 'rediger.view', true), ('planif_post', 'rediger.generate_post', true),
  ('planif_post', 'calendrier.view', true), ('planif_post', 'calendrier.file_editoriale', true),
  ('planif_post', 'brouillons.view', true), ('planif_post', 'avalider.view', true),
  ('planif_post', 'avalider.publish', true), ('planif_post', 'params.feeds', true)
on conflict (plan_key, feature_key) do nothing;

insert into public.elocia_plan_features (plan_key, feature_key, enabled)
values
  ('audit_profil', 'inspiration.view', true), ('audit_profil', 'bibliotheque.view', true),
  ('audit_profil', 'strategie.view', true), ('audit_profil', 'params.feeds', true)
on conflict (plan_key, feature_key) do nothing;
