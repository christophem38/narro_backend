-- Suppression des « Hot topics ».
--
-- POURQUOI : doublon avec le digest hebdomadaire. Les deux tournaient dans le
-- MÊME cron (lundi 7 h), sur les MÊMES news, et produisaient chacun 5 éléments
-- avec un titre, une explication, un angle LinkedIn, des sources et un score.
--
-- Le digest est la version supérieure : son `why_it_matters` est personnalisé
-- (« pourquoi c'est important pour VOUS, vu votre rôle et votre audience ») et
-- il recommande une posture. Les hot topics se contentaient de regrouper les
-- news parlant du même sujet.
--
-- Surtout : AUCUN écran ne les affichait. `fetchLatestHotTopics` existait mais
-- n'était appelée nulle part, et les deux composants d'affichage n'étaient
-- montés sur aucune page. On payait donc un second appel Claude chaque lundi,
-- par abonné, pour une donnée que personne ne pouvait voir — tout en la
-- facturant dans l'offre Solo.
--
-- La table est conservée pour l'instant : la supprimer effacerait
-- définitivement d'éventuelles données déjà générées. À supprimer dans une
-- migration ultérieure une fois qu'on aura confirmé qu'elle est vide.

-- 1) Retirer la fonctionnalité de toutes les offres.
delete from public.elocia_plan_features
  where feature_key = 'inspiration.hot_topics';

-- 2) Retirer la fonctionnalité du catalogue : elle ne doit plus apparaître
--    dans la matrice du Super Admin, où l'activer ne faisait déjà rien.
delete from public.elocia_features
  where key = 'inspiration.hot_topics';
