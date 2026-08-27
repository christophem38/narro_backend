-- Curation des avatars : 24 -> 11.
--
-- Seuls les personnages au TRAIT FONCÉ (teal #0B5F57) sur disque clair sont
-- conservés — les variantes inversées (perso clair sur disque teal foncé) se
-- lisaient mal en petit (36 px dans la sidebar). Les fichiers SVG des 13
-- retirés ont été supprimés du frontend.
--
-- COUPLAGE : la liste ci-dessous doit suivre ELOCIA_AVATARS dans
-- narro_frontend/lib/avatars.ts. Un id inconnu ferait retomber le front sur
-- les initiales (sans casse), d'où le remap ci-dessous.

-- 1) Nouveaux profils : un personnage au hasard parmi les 11 conservés.
alter table public.elocia_profiles
  alter column avatar
  set default (
    (array['e01','e04','e05','e08','e09','e12','e13','e17','e20','e21','e24'])
    [floor(random() * 11)::int + 1]
  );

-- 2) Comptes portant un avatar retiré : on les bascule sur un conservé
--    (random() réévalué par ligne). Les avatars conservés et le choix
--    « initiales » (NULL) ne sont pas touchés.
update public.elocia_profiles
  set avatar = (
    (array['e01','e04','e05','e08','e09','e12','e13','e17','e20','e21','e24'])
    [floor(random() * 11)::int + 1]
  )
  where avatar is not null
    and avatar not in ('e01','e04','e05','e08','e09','e12','e13','e17','e20','e21','e24');
