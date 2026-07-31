-- 0039_free_tier_generator_only.sql
-- Recadre les droits du tier "free" :
--   CRÉER : le Générateur uniquement (rediger.view).
--   GÉRER : toutes les pages SAUF "Mes sources", soit
--           Mes posts (brouillons.view), Calendrier (calendrier.view),
--           Performances (performances.view).
--
-- Astuce du modèle de données : "Mes sources" (Gérer) et "Inspiration" (Créer)
-- partagent la MÊME clé inspiration.view. La désactiver masque donc les deux —
-- ce qui correspond exactement à l'objectif (Générateur seul dans Créer,
-- Sources exclue dans Gérer). La sidebar filtre chaque entrée sur sa featureKey
-- (voir components/Sidebar.tsx), donc les pages retirées disparaissent du menu.
--
-- Rappel : params.view, widget.feedback et toolkit.view sont universels (accordés
-- en code, cf. lib/feature-gate.ts) — Paramètres et Toolkit restent accessibles.
-- 2026-07-31

-- 1) Pages ACCESSIBLES en Free (créer la ligne si absente, réactiver sinon).
insert into public.elocia_plan_features (plan_key, feature_key, enabled)
values
  ('free', 'rediger.view',      true),   -- Générateur (Créer)
  ('free', 'brouillons.view',   true),   -- Mes posts (Gérer)
  ('free', 'calendrier.view',   true),   -- Calendrier (Gérer)
  ('free', 'performances.view', true)    -- Performances (Gérer)
on conflict (plan_key, feature_key)
  do update set enabled = true, updated_at = now();

-- 2) Pages RETIRÉES du Free (désactiver ; créer une ligne false si absente).
insert into public.elocia_plan_features (plan_key, feature_key, enabled)
values
  ('free', 'inspiration.view', false),   -- masque Inspiration (Créer) ET Mes sources (Gérer)
  ('free', 'labo.view',        false),   -- masque Rebond éditorial (Créer)
  ('free', 'tempsforts.view',  false)    -- garde Temps forts (Créer) masqué
on conflict (plan_key, feature_key)
  do update set enabled = false, updated_at = now();
