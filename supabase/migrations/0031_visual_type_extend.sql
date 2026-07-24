-- 0031 : aligner la contrainte visual_type sur les formats réellement proposés
--
-- La contrainte d'origine (0001) n'autorisait que 5 formats, alors que le
-- prompt de génération (lib/anthropic.ts) demande à Claude d'en choisir un
-- parmi 8 (ajout de album / video / poll). Résultat : dès qu'une suggestion
-- utilisait un de ces 3 formats, l'INSERT des 5 suggestions était rejeté d'un
-- bloc → page Inspiration vide malgré un appel IA réussi.
--
-- Le rename de table (0024) n'a pas renommé les contraintes : l'ancienne porte
-- encore le nom narro_*.

alter table public.elocia_suggested_posts
  drop constraint if exists narro_suggested_posts_visual_type_check;
alter table public.elocia_suggested_posts
  drop constraint if exists elocia_suggested_posts_visual_type_check;

alter table public.elocia_suggested_posts
  add constraint elocia_suggested_posts_visual_type_check
  check (visual_type in ('image','album','video','carousel','poll','chart','quote','none'));
