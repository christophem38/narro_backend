-- UI pivot from "Suggestions" to "Inspirations" structured around the
-- Créer / Gérer / Piloter taxonomy.

alter table public.narro_suggested_posts
  add column if not exists why_now text;

-- The objective_badge constraint stays open (text) but UI now uses 6 exact
-- values:
--   Installer une vision
--   Déclencher une conversation
--   Renforcer la marque employeur
--   Réagir à une actualité marché
--   Valoriser une expertise interne
--   Préparer un temps fort commercial
