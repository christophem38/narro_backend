-- 0065 : SÉCURITÉ — security_invoker sur les vues d'administration
--
-- Faille corrigée (audit 2026-09-03, bloc A8) : sur PostgreSQL, une VIEW
-- ignore par défaut la RLS des tables sous-jacentes. Les 3 vues admin
-- retournaient donc la liste COMPLÈTE des 17 users (emails, roles, tier,
-- consommation IA) à n'importe quel authenticated.
--
-- Après : chaque vue s'exécute avec les permissions de l'appelant.
-- Les policies SELECT existantes sur elocia_profiles / elocia_ai_calls /
-- elocia_events / elocia_published_posts / elocia_suggested_posts
-- autorisent déjà admin+super_admin à tout voir, et cloisonnent les
-- clients à leurs propres lignes.

ALTER VIEW public.elocia_admin_user_stats SET (security_invoker = true);
ALTER VIEW public.elocia_ai_usage_per_profile SET (security_invoker = true);
ALTER VIEW public.elocia_ai_usage_per_feature SET (security_invoker = true);
