-- Avatar attribué au hasard, au lieu de laisser le profil sans avatar.
--
-- Pourquoi : un compte neuf affichait ses initiales dans un rond gris. Rien
-- n'indiquait qu'un choix existait, donc personne n'allait ouvrir le
-- sélecteur. En posant d'emblée un personnage, on rend la personnalisation
-- visible : on découvre qu'on a un avatar, donc qu'on peut en changer.
--
-- Deux effets :
--   1) DEFAULT sur la colonne  -> tout nouveau profil en reçoit un. Le profil
--      est créé par le trigger sur auth.users, dont l'INSERT ne cite pas
--      `avatar` : le DEFAULT s'applique donc sans toucher au trigger.
--   2) Rattrapage des comptes existants encore à NULL.
--
-- COUPLAGE : les ids vont de e01 à e24 et doivent suivre ELOCIA_AVATARS dans
-- narro_frontend/lib/avatars.ts (fichier auto-généré). Si le nombre d'avatars
-- change, ajuster le 24 ci-dessous — un id inconnu ferait retomber le front
-- sur les initiales, sans casse.
--
-- Choisir un avatar reste libre, y compris revenir aux initiales : le
-- sélecteur écrit alors NULL, et cette valeur est conservée (le rattrapage
-- ci-dessous ne s'exécute qu'une fois, à l'application de la migration).

-- La colonne doit exister (migration 0041). Rejouable sans risque.
alter table public.elocia_profiles
  add column if not exists avatar text;

-- 1) Nouveaux profils : un personnage au hasard parmi e01..e24.
alter table public.elocia_profiles
  alter column avatar
  set default 'e' || lpad((floor(random() * 24) + 1)::int::text, 2, '0');

-- 2) Comptes existants sans avatar : on leur en attribue un, différent d'une
--    ligne à l'autre (random() est réévalué pour chaque ligne).
update public.elocia_profiles
  set avatar = 'e' || lpad((floor(random() * 24) + 1)::int::text, 2, '0')
  where avatar is null;
