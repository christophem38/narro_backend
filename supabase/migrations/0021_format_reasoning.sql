-- 0021_format_reasoning.sql
-- Ajoute la justification du choix de format visuel pour chaque
-- proposition d'inspiration. Stocke pourquoi Claude pense que ce
-- visual_type (image / carousel / chart / quote / none) est le mieux
-- adapte au sujet ET au profil utilisateur.
-- 2026-06-24

alter table public.narro_suggested_posts
  add column if not exists format_reasoning text;
