-- 0034 : Historique des versions d'un post (boucle noter -> regenerer)
--
-- CONTEXTE : le Generateur sait noter un post sur 5 axes (action aiScorePost,
--   cf. lib/anthropic.ts scorePost). Chaque axe renvoie une « amelioration »
--   concrete. Jusqu'ici ces retours n'etaient que lus : aucun moyen de
--   demander une reecriture qui les prenne en compte, et les versions
--   successives ne vivaient qu'en memoire du navigateur (fleches
--   annuler/retablir), donc perdues au rechargement.
--
-- APRES : chaque brouillon porte son historique de versions. Une version =
--   un texte + la note obtenue (si elle a ete notee) + la liste des axes de
--   retour qui ont servi a la produire. L'utilisateur peut revenir a
--   n'importe quelle version.
--
-- CHOIX DU JSONB plutot qu'une table dediee : les versions d'un post sont
--   toujours lues et ecrites ensemble, avec le post, et ne sont jamais
--   requetees en transverse. Une colonne evite une jointure sur tous les
--   ecrans qui listent des brouillons.
--
-- Forme de chaque element du tableau :
--   {
--     "n": 1,                            -- numero de version, 1-based
--     "text": "...",                     -- le post
--     "created_at": "2026-07-24T...",
--     "score": { "total": 72, "criteria": [...], "global_advice": "..." },
--     "applied": ["Valeur apportée", "Accroche & lisibilité"]
--   }
--   `score` vaut null tant que la version n'a pas ete notee.
--   `applied` est vide pour la version initiale.
--
-- Idempotent.

alter table public.elocia_suggested_posts
  add column if not exists versions jsonb not null default '[]'::jsonb;

comment on column public.elocia_suggested_posts.versions is
  'Historique des versions du post : [{n, text, created_at, score, applied}]. Ecrit par le Generateur (boucle noter -> regenerer).';
