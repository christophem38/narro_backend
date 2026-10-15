-- 0072 : roadmap par horizons (court / moyen / long terme) + propositions de l'IA
-- issues des comptes rendus de points.
--
-- Trois ajouts, tous additifs et rejouables :
--  1. un `horizon` sur les jalons et les chantiers (vide = « à classer ») ;
--  2. un lien chantier → idée (`improvement_id`) pour suivre l'avancement via les
--     améliorations de l'agent (sans clé étrangère : la table des idées n'existe
--     pas forcément sur tous les environnements) ;
--  3. deux tables : les comptes rendus de points (`elocia_roadmap_points`) et ce
--     que l'IA en tire (`elocia_roadmap_propositions`), à valider une par une.
--
-- Horizons : court = jusqu'à 3 mois, moyen = 3 à 6 mois, long = plus d'un an.
-- Lecture et écriture : super_admin uniquement (l'agent passe par la clé de service).

alter table public.elocia_roadmap_jalons
  add column if not exists horizon text
  check (horizon is null or horizon in ('court', 'moyen', 'long'));

alter table public.elocia_roadmap_chantiers
  add column if not exists horizon text
  check (horizon is null or horizon in ('court', 'moyen', 'long'));

alter table public.elocia_roadmap_chantiers
  add column if not exists improvement_id uuid;

create index if not exists elocia_roadmap_chantiers_improvement_idx
  on public.elocia_roadmap_chantiers (improvement_id)
  where improvement_id is not null;

-- Comptes rendus de points (texte collé dans Élocia).
create table if not exists public.elocia_roadmap_points (
  id           uuid primary key default gen_random_uuid(),
  point_date   date not null default current_date,
  titre        text not null default '',
  contenu      text not null default '',
  created_by   text,
  created_at   timestamptz not null default now(),
  -- Renseigné quand l'IA a lu le compte rendu et déposé ses propositions.
  processed_at timestamptz
);

-- Ce que l'IA propose d'ajouter ou de changer. Rien n'entre dans la roadmap sans
-- un clic : « accepted » est posé par la super-admin, jamais par l'agent.
create table if not exists public.elocia_roadmap_propositions (
  id                 uuid primary key default gen_random_uuid(),
  point_id           uuid references public.elocia_roadmap_points(id) on delete cascade,
  kind               text not null
                     check (kind in ('chantier', 'arbitrage', 'dette', 'etat')),
  titre              text not null default '',
  detail             text not null default '',
  horizon            text check (horizon is null or horizon in ('court', 'moyen', 'long')),
  -- Où ranger la proposition si elle est acceptée (facultatif).
  jalon_id           uuid references public.elocia_roadmap_jalons(id) on delete set null,
  -- Pour kind = 'etat' : le chantier concerné et le nouvel état proposé.
  chantier_id        uuid references public.elocia_roadmap_chantiers(id) on delete cascade,
  etat_propose       text check (etat_propose is null
                     or etat_propose in ('fait', 'en_cours', 'a_faire', 'bloque_externe')),
  -- Phrase du compte rendu qui justifie la proposition.
  extrait            text not null default '',
  status             text not null default 'pending'
                     check (status in ('pending', 'accepted', 'rejected')),
  created_at         timestamptz not null default now(),
  decided_at         timestamptz,
  decided_by         text
);

create index if not exists elocia_roadmap_propositions_status_idx
  on public.elocia_roadmap_propositions (status, created_at);

alter table public.elocia_roadmap_points enable row level security;
drop policy if exists roadmap_points_super_admin on public.elocia_roadmap_points;
create policy roadmap_points_super_admin on public.elocia_roadmap_points
  for all to authenticated
  using (public.narro_current_role() = 'super_admin')
  with check (public.narro_current_role() = 'super_admin');
grant select, insert, update, delete on public.elocia_roadmap_points to authenticated;

alter table public.elocia_roadmap_propositions enable row level security;
drop policy if exists roadmap_propositions_super_admin on public.elocia_roadmap_propositions;
create policy roadmap_propositions_super_admin on public.elocia_roadmap_propositions
  for all to authenticated
  using (public.narro_current_role() = 'super_admin')
  with check (public.narro_current_role() = 'super_admin');
grant select, insert, update, delete on public.elocia_roadmap_propositions to authenticated;

-- Horizons évidents des deux premiers jalons (seulement s'ils n'en ont pas encore).
-- « Offre Entreprise » reste à classer : la cible entreprise a changé la donne.
update public.elocia_roadmap_jalons set horizon = 'court'
  where horizon is null and nom = 'Lancement du plan gratuit';
update public.elocia_roadmap_jalons set horizon = 'moyen'
  where horizon is null and nom like 'Offre Pro%';

-- Premier remplissage : le point du 14/10/2026 et ses propositions (à valider).
-- Ne s'exécute qu'une fois.
do $$
declare
  v_point uuid;
  v_entreprise uuid;
begin
  if exists (select 1 from public.elocia_roadmap_points where titre = 'Point du 14/10/2026') then
    return;
  end if;

  select id into v_entreprise from public.elocia_roadmap_jalons where nom = 'Offre Entreprise' limit 1;

  insert into public.elocia_roadmap_points (point_date, titre, contenu, created_by, processed_at)
  values (
    '2026-10-14',
    'Point du 14/10/2026',
    'Priorité actuelle : un bon Générateur et un parcours utilisateur le plus pertinent possible.

1. Séparer l''IA qui génère le post de celle qui le note, pour éviter le biais (par exemple Claude génère et DeepSeek note, ou l''inverse).
2. Dans le chat du hub d''amélioration, l''IA profile l''utilisateur pour poser les bonnes questions, mieux cadrer, mieux noter et mieux améliorer le post.
3. Cadrage : questions avec 4 ou 5 suggestions de réponse plus « Autre » en saisie libre, comme Claude. Mettre davantage en avant le nombre de caractères du post généré.
4. L''entreprise devient la première cible : profil admin pour le dirigeant qui gère la communication LinkedIn, et circuit de relecture (le stagiaire génère et améliore, d''autres personnes relisent).
5. Envisager un modèle LoRA pour nourrir un modèle maison.

Compte rendu complet : docs/points/2026-10-14-point-elocia.md.',
    'Claude (premier remplissage)',
    now()
  )
  returning id into v_point;

  insert into public.elocia_roadmap_propositions (point_id, kind, titre, detail, horizon, jalon_id, extrait) values
  (v_point, 'chantier',
   'Séparer le modèle qui génère du modèle qui note',
   'Aujourd''hui le Générateur génère, note et réécrit avec le même modèle : la note est trop flatteuse. Choisir un modèle de notation différent (piste DeepSeek, à arbitrer : données envoyées à un fournisseur supplémentaire).',
   'court', null,
   'Il faudrait différencier l''IA qui génère le post et l''IA qui le note, pour éviter qu''il y ait un biais.'),
  (v_point, 'chantier',
   'Cadrage : questions à 4-5 réponses suggérées + « Autre » en saisie libre',
   'Même principe que les questions à options de Claude, dans le chat du hub d''amélioration.',
   'court', null,
   'Il faudrait que ce soit un peu comme Claude quand il pose une question avec 4 ou 5 suggestions de réponses.'),
  (v_point, 'chantier',
   'Mettre en avant le nombre de caractères du post généré',
   'Afficher le nombre de caractères de façon plus visible dès que le post est généré.',
   'court', null,
   'Il faudrait mettre un peu plus en avant le nombre de caractères du post quand il a été généré.'),
  (v_point, 'chantier',
   'L''IA du hub profile l''utilisateur pour poser les bonnes questions',
   'Mieux cadrer, mieux noter et mieux améliorer le post selon l''utilisateur. S''appuie sur Ma voix éditoriale et sur le prototype d''onboarding en chat.',
   'moyen', null,
   'L''IA dans le hub d''amélioration, il faudrait qu''elle puisse profiler l''utilisateur pour poser les bonnes questions.'),
  (v_point, 'chantier',
   'Circuit de relecture : le stagiaire génère, d''autres relisent avant publication',
   'Statuts de post (brouillon, à relire, corrections demandées, validé, publié), commentaires de relecture, historique. Recoupe le chantier existant « Rôles et circuit de validation avant publication » : à fusionner si accepté.',
   'moyen', v_entreprise,
   'Le stagiaire génère un post, l''améliore, il faudrait qu''il y ait un système de relecture par d''autres personnes.'),
  (v_point, 'chantier',
   'Profil dirigeant / admin d''entreprise',
   'Le dirigeant (ou la personne qui gère toute la communication LinkedIn) pilote l''équipe et le process de relecture.',
   'moyen', v_entreprise,
   'L''entreprise va devenir la première cible d''Elocia.'),
  (v_point, 'chantier',
   'Modèle LoRA maison',
   'Entraîner une adaptation légère d''un modèle ouvert sur les posts validés et les corrections des relecteurs. Dépend du circuit de relecture et de l''accord des clients sur l''usage de leurs données.',
   'long', null,
   'On aimerait bien envisager aussi un modèle LoRA pour nourrir notre propre modèle.'),
  (v_point, 'arbitrage',
   'La cible entreprise change-t-elle le calendrier du jalon « Offre Entreprise » ?',
   'Il est daté « 2027 » avec une confiance faible, alors que l''entreprise devient la première cible. À re-situer par rapport au Générateur et au parcours utilisateur, qui restent la priorité.',
   null, null,
   'L''entreprise va devenir la première cible d''Elocia. Pour l''instant la priorité, c''est de construire un bon générateur et un user journey vraiment pertinent.'),
  (v_point, 'arbitrage',
   'LoRA : données d''entraînement et consentement des clients',
   'Quelles données (posts validés, notes, corrections), avec quel accord des clients (RGPD), pour quel volume et quel coût ?',
   'long', null,
   'On aimerait bien envisager aussi un modèle LoRA pour nourrir notre propre modèle.');
end $$;

notify pgrst, 'reload schema';
