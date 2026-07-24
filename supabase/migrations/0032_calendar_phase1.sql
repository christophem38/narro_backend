-- 0032 : Calendrier — phase 1 (fiabilisation)
--
-- 1) Fuseau horaire par profil.
--    Le calendrier positionnait chaque post sur la journee calculee dans le
--    fuseau du NAVIGATEUR (new Date(published_at) + comparaison locale). Un
--    post publie a 23h a Paris tombait la veille pour un lecteur a Montreal.
--    On stocke un fuseau de reference par profil, seed depuis country_code.
--
-- 2) Statut 'approved'.
--    L'UI du calendrier declare 7 statuts dont 'approved' (chip bleue, filtre
--    « Valides », compteur), mais la contrainte posee en 0029 n'autorisait que
--    draft / awaiting_validation / published / expired : aucune ecriture ne
--    pouvait produire ce statut, le filtre affichait toujours 0.
--    NB : 'scheduled' sera ajoute en phase 2 (bascule de la planification vers
--    elocia_suggested_posts.scheduled_for) — pas ici, pour garder la migration
--    de backfill des posts programmes isolee.
--
-- 3) Index de support : filtrage par statut, et deduplication brouillon /
--    post deja programme (jointure sur origin_suggested_id).
--
-- Idempotent.

-- =========================================================================
-- 1) Fuseau horaire
-- =========================================================================
alter table public.elocia_profiles
  add column if not exists timezone text not null default 'Europe/Paris';

-- Aligne le fuseau sur le pays deja renseigne (les 3 pays servis aujourd'hui).
-- Ne touche que les lignes restees sur le defaut, pour ne jamais ecraser un
-- choix explicite de l'utilisateur lors d'un rejeu de la migration.
update public.elocia_profiles
   set timezone = case country_code
                    when 'FR' then 'Europe/Paris'
                    when 'BE' then 'Europe/Brussels'
                    when 'CH' then 'Europe/Zurich'
                    else timezone
                  end
 where timezone = 'Europe/Paris'
   and country_code in ('BE', 'CH');

-- =========================================================================
-- 2) Statut 'approved'
-- =========================================================================
-- La contrainte peut porter son nom d'origine narro_* : un rename de table
-- (migration 0024) ne renomme pas les contraintes. On tente les deux.
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
    check (status in ('draft','awaiting_validation','approved','published','expired'));
end$$;

-- =========================================================================
-- 3) Index de support
-- =========================================================================
create index if not exists elocia_suggested_posts_profile_status_idx
  on public.elocia_suggested_posts (profile_id, status);

-- Deduplication : retrouver les suggested_posts qui ont deja engendre un
-- published_post (cas d'un post programme dont la source reste en brouillon).
create index if not exists elocia_published_posts_origin_idx
  on public.elocia_published_posts (profile_id, origin_suggested_id)
  where origin_suggested_id is not null;
