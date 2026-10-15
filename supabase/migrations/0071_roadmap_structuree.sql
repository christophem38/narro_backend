-- 0071 : roadmap produit en données structurées (une ligne par jalon / chantier).
--
-- Avant : un unique bloc de texte YAML (table `roadmap_doc`), modifiable
-- seulement en réécrivant la syntaxe à la main. Inutilisable pour un
-- super-admin qui veut juste cocher un chantier, et tout le document partait
-- d'un coup — donc conflits et brouillons perdus.
--
-- Après : de vraies lignes. Chaque geste (cocher un état, renommer un jalon)
-- s'enregistre seul, sans toucher au reste : plus de conflit entre deux
-- super-admins. Le texte reste accessible en « mode avancé », reconstruit à la
-- lecture et réimporté à l'écriture.
--
-- Les trois champs quasi identiques `note` / `reste` / `detail` fusionnent en
-- un seul `commentaire` (leur contenu est concaténé ci-dessous, rien n'est
-- perdu). `actions_hors_code` devient un texte multi-ligne, une action par
-- ligne. Lecture et écriture : super_admin uniquement. Idempotente.

create table if not exists public.elocia_roadmap_jalons (
  id            uuid primary key default gen_random_uuid(),
  ordre         int  not null default 0,
  nom           text not null default '',
  echeance      text not null default '',
  objectif      text not null default '',
  confiance     text not null default '',
  avertissement text not null default '',
  actions       text not null default '',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create table if not exists public.elocia_roadmap_chantiers (
  id          uuid primary key default gen_random_uuid(),
  jalon_id    uuid not null references public.elocia_roadmap_jalons(id) on delete cascade,
  ordre       int  not null default 0,
  item        text not null default '',
  etat        text not null default 'a_faire'
              check (etat in ('fait', 'en_cours', 'a_faire', 'bloque_externe')),
  source      text not null default ''
              check (source in ('', 'verifie_code', 'verifie_chat', 'extrapole')),
  commentaire text not null default '',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Ce qui ne tient pas dans un jalon : arbitrages ouverts et dette technique.
create table if not exists public.elocia_roadmap_notes (
  id         uuid primary key default gen_random_uuid(),
  categorie  text not null check (categorie in ('arbitrage', 'dette')),
  ordre      int  not null default 0,
  titre      text not null default '',
  detail     text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Ligne unique : qui a touché la roadmap en dernier, et quand.
create table if not exists public.elocia_roadmap_meta (
  id         int primary key default 1 check (id = 1),
  titre      text not null default 'Elocia',
  version    text not null default '',
  updated_at timestamptz not null default now(),
  updated_by text
);

create index if not exists elocia_roadmap_chantiers_jalon_idx
  on public.elocia_roadmap_chantiers (jalon_id, ordre);
create index if not exists elocia_roadmap_notes_cat_idx
  on public.elocia_roadmap_notes (categorie, ordre);

alter table public.elocia_roadmap_jalons enable row level security;
drop policy if exists roadmap_jalons_super_admin on public.elocia_roadmap_jalons;
create policy roadmap_jalons_super_admin on public.elocia_roadmap_jalons
  for all to authenticated
  using (public.narro_current_role() = 'super_admin')
  with check (public.narro_current_role() = 'super_admin');
grant select, insert, update, delete on public.elocia_roadmap_jalons to authenticated;

alter table public.elocia_roadmap_chantiers enable row level security;
drop policy if exists roadmap_chantiers_super_admin on public.elocia_roadmap_chantiers;
create policy roadmap_chantiers_super_admin on public.elocia_roadmap_chantiers
  for all to authenticated
  using (public.narro_current_role() = 'super_admin')
  with check (public.narro_current_role() = 'super_admin');
grant select, insert, update, delete on public.elocia_roadmap_chantiers to authenticated;

alter table public.elocia_roadmap_notes enable row level security;
drop policy if exists roadmap_notes_super_admin on public.elocia_roadmap_notes;
create policy roadmap_notes_super_admin on public.elocia_roadmap_notes
  for all to authenticated
  using (public.narro_current_role() = 'super_admin')
  with check (public.narro_current_role() = 'super_admin');
grant select, insert, update, delete on public.elocia_roadmap_notes to authenticated;

alter table public.elocia_roadmap_meta enable row level security;
drop policy if exists roadmap_meta_super_admin on public.elocia_roadmap_meta;
create policy roadmap_meta_super_admin on public.elocia_roadmap_meta
  for all to authenticated
  using (public.narro_current_role() = 'super_admin')
  with check (public.narro_current_role() = 'super_admin');
grant select, insert, update, delete on public.elocia_roadmap_meta to authenticated;

-- Contenu de départ : l'ébauche du 7 octobre, reprise à l'identique.
-- Ne s'exécute que si la roadmap est vide (donc rejouable sans doublon).
do $$
declare v_jalon uuid;
begin
  if exists (select 1 from public.elocia_roadmap_jalons) then return; end if;

  insert into public.elocia_roadmap_meta (id, titre, version) values (1, 'Elocia', 'ébauche')
    on conflict (id) do nothing;


  insert into public.elocia_roadmap_jalons (ordre, nom, echeance, objectif, confiance, avertissement, actions)
  values (0, 'Lancement du plan gratuit', '2026-10-31', 'Ouvrir Elocia au public, sans paiement', 'haute', '', 'Appliquer les migrations 0046 et 0061 en production
Poser NEXT_PUBLIC_SITE_URL
Vérifier que HUB_URL et HUB_KEY sont définis ensemble
Activer Vercel Web Analytics
Supprimer les 2 comptes de test d''audit')
  returning id into v_jalon;

  insert into public.elocia_roadmap_chantiers (jalon_id, ordre, item, etat, source, commentaire)
  values (v_jalon, 0, 'Ouverture publique (middleware non bloquant, pages marketing)', 'fait', 'verifie_code', '');

  insert into public.elocia_roadmap_chantiers (jalon_id, ordre, item, etat, source, commentaire)
  values (v_jalon, 1, 'Quota gratuit à 15 générations/jour', 'en_cours', 'verifie_code', 'migration 0061 à appliquer en prod (sinon la carte de prix affiche encore 30)');

  insert into public.elocia_roadmap_chantiers (jalon_id, ordre, item, etat, source, commentaire)
  values (v_jalon, 2, 'Auto-upgrade bloqué pour les non-admins', 'fait', 'verifie_code', '');

  insert into public.elocia_roadmap_chantiers (jalon_id, ordre, item, etat, source, commentaire)
  values (v_jalon, 3, 'SEO/GEO (robots, sitemap, JSON-LD, llms.txt, OG)', 'fait', 'verifie_code', '');

  insert into public.elocia_roadmap_chantiers (jalon_id, ordre, item, etat, source, commentaire)
  values (v_jalon, 4, 'Nom de domaine dédié + emails transactionnels (Resend)', 'a_faire', 'verifie_chat', '');

  insert into public.elocia_roadmap_chantiers (jalon_id, ordre, item, etat, source, commentaire)
  values (v_jalon, 5, 'Connexion LinkedIn', 'bloque_externe', 'verifie_code', 'placeholder « bientôt disponible » ; API officielle demandée, non accordée');


  insert into public.elocia_roadmap_jalons (ordre, nom, echeance, objectif, confiance, avertissement, actions)
  values (1, 'Offre Pro — première version payante', '2026-12-31', 'Encaisser, et justifier l''écart de prix par de la valeur réelle', 'moyenne', '', '')
  returning id into v_jalon;

  insert into public.elocia_roadmap_chantiers (jalon_id, ordre, item, etat, source, commentaire)
  values (v_jalon, 0, 'Paiement Stripe (checkout, webhooks, portail client)', 'a_faire', 'verifie_code', 'Priorité 1 — rien n''existe dans le repo ; bloque TOUTE la version payante');

  insert into public.elocia_roadmap_chantiers (jalon_id, ordre, item, etat, source, commentaire)
  values (v_jalon, 1, 'Quota Solo à 30 générations/jour', 'en_cours', 'verifie_code', 'même migration 0061');

  insert into public.elocia_roadmap_chantiers (jalon_id, ordre, item, etat, source, commentaire)
  values (v_jalon, 2, 'Publication directe sur LinkedIn', 'bloque_externe', 'verifie_code', 'dépend d''un accord qu''on ne maîtrise pas → à vendre en option, pas en promesse');

  insert into public.elocia_roadmap_chantiers (jalon_id, ordre, item, etat, source, commentaire)
  values (v_jalon, 3, 'Enrichissement du profil via le site de l''entreprise', 'a_faire', 'verifie_chat', 'le champ company_website est collecté, l''enrichissement n''existe pas');

  insert into public.elocia_roadmap_chantiers (jalon_id, ordre, item, etat, source, commentaire)
  values (v_jalon, 4, 'Boucle d''apprentissage (performances publiées → classement des suggestions)', 'a_faire', 'verifie_code', 'generateWeeklySuggestions ne reçoit aucune métrique d''engagement');

  insert into public.elocia_roadmap_chantiers (jalon_id, ordre, item, etat, source, commentaire)
  values (v_jalon, 5, 'Planification éditoriale pilotée par les objectifs (allocation par pilier)', 'a_faire', 'verifie_chat', '');


  insert into public.elocia_roadmap_jalons (ordre, nom, echeance, objectif, confiance, avertissement, actions)
  values (2, 'Offre Entreprise', '2027', 'Servir des équipes, pas des individus', 'faible', 'Les paliers team (30 sources) et enterprise (illimité) existent déjà dans lib/plan-limits.ts, mais rien d''autre. Ces 5 lignes sont ma proposition.', '')
  returning id into v_jalon;

  insert into public.elocia_roadmap_chantiers (jalon_id, ordre, item, etat, source, commentaire)
  values (v_jalon, 0, 'Espaces d''équipe / multi-comptes', 'a_faire', 'extrapole', '');

  insert into public.elocia_roadmap_chantiers (jalon_id, ordre, item, etat, source, commentaire)
  values (v_jalon, 1, 'Rôles et circuit de validation avant publication', 'a_faire', 'extrapole', '');

  insert into public.elocia_roadmap_chantiers (jalon_id, ordre, item, etat, source, commentaire)
  values (v_jalon, 2, 'Charte de marque partagée entre les membres', 'a_faire', 'extrapole', '');

  insert into public.elocia_roadmap_chantiers (jalon_id, ordre, item, etat, source, commentaire)
  values (v_jalon, 3, 'SSO + facturation centralisée', 'a_faire', 'extrapole', '');

  insert into public.elocia_roadmap_chantiers (jalon_id, ordre, item, etat, source, commentaire)
  values (v_jalon, 4, 'API et intégrations', 'a_faire', 'extrapole', '');


  insert into public.elocia_roadmap_notes (categorie, ordre, titre, detail)
  values ('arbitrage', 0, 'Cadrage conversationnel de l''onboarding', 'argument du gratuit (J1) ou différenciateur du Pro (J2) ? — app/onboarding/ChatOnboardingPreview.tsx — accessible en aperçu superadmin uniquement');

  insert into public.elocia_roadmap_notes (categorie, ordre, titre, detail)
  values ('arbitrage', 1, 'Palier de quota au-dessus de Solo', 'Solo 30/jour puis Pro 300/jour est un saut brutal — quelle valeur pour Pro ?');

  insert into public.elocia_roadmap_notes (categorie, ordre, titre, detail)
  values ('dette', 0, 'Verrou d''idempotence sur la génération des suggestions hebdo', 'risque : double facturation si rafraîchissement ou deux onglets');

  insert into public.elocia_roadmap_notes (categorie, ordre, titre, detail)
  values ('dette', 1, 'Le cron refresh-feeds tourne sans filtre d''offre', '');

end $$;

notify pgrst, 'reload schema';
