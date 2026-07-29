-- 0038_fix_event_source_tag_check.sql
-- Bug herite du rebrand : la migration 0024 a renomme narro_events ->
-- elocia_events mais a laisse le CHECK de source_tag sur l'ancienne valeur
-- 'narro_detected'. Or le code (page ET cron) insere 'elocia_detected' :
-- ces insertions de temps forts DETECTES etaient donc rejetees par le CHECK,
-- et seuls les evenements 'user_added' (defaut de la colonne) etaient enregistres.
--
-- On elargit le CHECK a 'elocia_detected' et on migre les eventuelles lignes
-- restees en 'narro_detected'.
-- 2026-07-29

-- 1) Retirer l'ancien CHECK (le nom date d'avant le rename de table ; on tente
--    les deux noms possibles, de facon idempotente).
alter table public.elocia_events
  drop constraint if exists narro_events_source_tag_check;
alter table public.elocia_events
  drop constraint if exists elocia_events_source_tag_check;

-- 2) Migrer les valeurs historiques.
update public.elocia_events
   set source_tag = 'elocia_detected'
 where source_tag = 'narro_detected';

-- 3) Nouveau CHECK avec la bonne valeur 'elocia_detected'.
alter table public.elocia_events
  add constraint elocia_events_source_tag_check
  check (source_tag in ('user_added', 'elocia_detected', 'marronnier'));
