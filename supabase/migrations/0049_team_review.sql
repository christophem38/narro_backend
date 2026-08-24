-- Relecture d'équipe (offre Pro et au-dessus).
--
-- CONTEXTE : la table `elocia_teams` et la colonne `profiles.team_id` existent
-- depuis la migration 0005, mais RIEN ne les utilisait. Chaque post n'était
-- visible que de son auteur (`self_read` : profile_id = auth.uid()), donc la
-- « validation équipe » vendue dans l'offre Pro n'était qu'une AUTO-relecture :
-- on s'envoyait son propre post et on se l'approuvait.
--
-- Cette migration rend la relecture réellement collective :
--   1. deux fonctions d'appartenance à une équipe (SECURITY DEFINER, pour ne
--      pas retomber dans la récursion RLS corrigée en 0004) ;
--   2. la traçabilité de qui a soumis et qui a approuvé ;
--   3. deux politiques : un coéquipier peut LIRE et APPROUVER les posts de son
--      équipe qui sont en attente de relecture.
--
-- PÉRIMÈTRE VOLONTAIREMENT ÉTROIT : un coéquipier ne voit QUE les posts au
-- statut `awaiting_validation`. Les brouillons restent privés — on ne donne pas
-- accès aux notes en cours d'écriture de ses collègues, seulement à ce qui a
-- été explicitement soumis.

-- 1) Appartenance à une équipe ------------------------------------------------

-- Équipe de l'utilisateur courant. SECURITY DEFINER : lire `elocia_profiles`
-- depuis une politique de `elocia_suggested_posts` déclencherait sinon
-- l'évaluation RLS de profiles, d'où récursion (cf. 0004).
create or replace function public.elocia_my_team_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select team_id from public.elocia_profiles where id = auth.uid();
$$;

revoke all on function public.elocia_my_team_id() from public;
grant execute on function public.elocia_my_team_id() to authenticated;

-- Équipe d'un profil donné (l'auteur du post).
create or replace function public.elocia_team_of(target uuid)
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select team_id from public.elocia_profiles where id = target;
$$;

revoke all on function public.elocia_team_of(uuid) from public;
grant execute on function public.elocia_team_of(uuid) to authenticated;

-- 2) Traçabilité --------------------------------------------------------------
-- `approved_at` existait déjà, mais pas QUI a approuvé : sans cette colonne,
-- une relecture d'équipe ne laisse aucune trace exploitable.

alter table public.elocia_suggested_posts
  add column if not exists submitted_by uuid references public.elocia_profiles(id) on delete set null,
  add column if not exists submitted_at timestamptz,
  add column if not exists approved_by  uuid references public.elocia_profiles(id) on delete set null;

comment on column public.elocia_suggested_posts.submitted_by is
  'Qui a envoyé le post en relecture (en général l''auteur).';
comment on column public.elocia_suggested_posts.approved_by is
  'Qui a validé le post. Différent de profile_id = relecture par un coéquipier.';

-- 3) Politiques d'équipe ------------------------------------------------------

drop policy if exists team_review_read on public.elocia_suggested_posts;
create policy team_review_read on public.elocia_suggested_posts
  for select to authenticated
  using (
    status = 'awaiting_validation'
    and public.elocia_my_team_id() is not null
    and public.elocia_team_of(profile_id) = public.elocia_my_team_id()
  );

-- Un coéquipier peut faire AVANCER un post soumis : l'approuver, ou le renvoyer
-- en brouillon pour correction. Les autres statuts (programmé, publié) restent
-- la main de l'auteur : on relit, on ne publie pas à sa place.
drop policy if exists team_review_update on public.elocia_suggested_posts;
create policy team_review_update on public.elocia_suggested_posts
  for update to authenticated
  using (
    status = 'awaiting_validation'
    and public.elocia_my_team_id() is not null
    and public.elocia_team_of(profile_id) = public.elocia_my_team_id()
  )
  with check (
    status in ('approved', 'draft')
    and public.elocia_team_of(profile_id) = public.elocia_my_team_id()
  );

-- Un post en relecture se retrouve plus vite quand la file est grande.
create index if not exists elocia_suggested_posts_awaiting_idx
  on public.elocia_suggested_posts (status, profile_id)
  where status = 'awaiting_validation';
