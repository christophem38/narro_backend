-- 0020_pertinence_justification.sql
-- Ajoute la justification de pertinence pour chaque suggestion :
-- pourquoi cette proposition est-elle pertinente pour CE profil
-- (objectifs, secteur, posture, piliers editoriaux).
-- Distincte de why_now qui parle de timing/momentum sectoriel.
-- 2026-06-24

alter table public.narro_suggested_posts
  add column if not exists pertinence_justification text;
