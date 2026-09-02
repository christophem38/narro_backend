-- 0061_plan_generation_quotas.sql
-- Aligne les cartes d'offres AFFICHÉES DANS L'APP sur les quotas réellement
-- appliqués par le code (lib/ai-quota.ts, lib/plan-limits.ts).
--
-- Contexte : la page de prix promettait des limites qui n'étaient appliquées
-- nulle part, et deux d'entre elles se contredisaient — le gratuit annonçait
-- « 30 générations par jour » quand Solo annonçait « 4 posts générés par
-- mois », soit une régression payante. Décision : la génération se compte en
-- APPELS IA PAR JOUR, gratuit 15 / Solo 30.
--
-- Rappel : ce quota couvre TOUTE action IA (rédaction, notation, autre
-- version, réécriture, fact-check), pas seulement la rédaction initiale.
-- 2026-08-28

update public.elocia_plans set highlights = array[
  'Rédigez vos posts avec l''IA, sans partir d''une page blanche',
  'Planifiez vos publications et suivez vos résultats',
  '15 générations par jour'
] where key = 'free';

update public.elocia_plans set highlights = array[
  '5 prises de parole prêtes à écrire, chaque semaine',
  'Votre veille transformée en sujets : 3 sources suivies',
  '30 générations par jour'
] where key = 'solo';
