-- 0036 : Sources croisees d'un post (Rebond editorial multi-signaux)
--
-- CONTEXTE : le Rebond editorial permet desormais de croiser plusieurs
--   signaux (articles et/ou conversations reseau) pour construire un angle
--   (cf. app/(app)/app/labo). Jusqu'ici, createDraftPost ne persistait que la
--   PREMIERE URL (source_url) et un libelle combine (source_title). Depuis le
--   Generateur, on ne pouvait donc rouvrir qu'un seul lien, meme si le post
--   croisait deux ou trois sources.
--
-- APRES : chaque brouillon garde la liste complete des sources utilisees, avec
--   pour chacune son libelle, son URL et son type. Le Generateur affiche un
--   lien cliquable par source dans la carte « Depuis le Rebond editorial ».
--
-- CHOIX DU JSONB : les sources d'un post sont toujours lues et ecrites avec le
--   post, jamais requetees en transverse. Une colonne evite une table dediee et
--   une jointure sur tous les ecrans qui listent des brouillons.
--
-- Forme de chaque element du tableau :
--   { "label": "First real money...", "url": "https://...", "kind": "news" }
--   `url` peut valoir null (post reseau ajoute a la main sans lien).
--   `kind` vaut "news" ou "influence".
--
-- Idempotent.

alter table public.elocia_suggested_posts
  add column if not exists source_refs jsonb;

comment on column public.elocia_suggested_posts.source_refs is
  'Sources croisees du Rebond editorial : [{label, url, kind}]. Ecrit par createDraftPost, lu par le Generateur pour afficher un lien par source.';
