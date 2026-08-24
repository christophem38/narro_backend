-- 0048 : libellés de fonctionnalités plus clairs (affichés dans les cartes
-- d'offres — modale d'upsell + /app/pricing).
--
-- Deux problèmes corrigés :
--   1. Les 11 fonctionnalités « .view » portaient toutes le même libellé
--      « Voir la page », donc indistinguables dans une liste à plat. On les
--      renomme « Accès <Page> ».
--   2. Plusieurs libellés « jargon » interne (Bloc…, Bandeau…, Quick add…)
--      deviennent des intitulés parlants pour un prospect.
--
-- Idempotent : de simples UPDATE par clé. Rejouable sans effet de bord.

-- 1) « Voir la page » -> « Accès <Page> »
update public.elocia_features set label = 'Accès Inspiration'            where key = 'inspiration.view';
update public.elocia_features set label = 'Accès au Générateur'          where key = 'rediger.view';
update public.elocia_features set label = 'Accès Calendrier'             where key = 'calendrier.view';
update public.elocia_features set label = 'Accès Temps forts'            where key = 'tempsforts.view';
update public.elocia_features set label = 'Accès Performances'           where key = 'performances.view';
update public.elocia_features set label = 'Accès à Mes posts'            where key = 'brouillons.view';
update public.elocia_features set label = 'Accès À valider'              where key = 'avalider.view';
update public.elocia_features set label = 'Accès Stratégie éditoriale'   where key = 'strategie.view';
update public.elocia_features set label = 'Accès Charte éditoriale'      where key = 'bibliotheque.view';
update public.elocia_features set label = 'Accès Paramètres'             where key = 'params.view';
update public.elocia_features set label = 'Accès Labo éditorial'         where key = 'labo.view';

-- 2) Libellés « jargon » -> clairs
update public.elocia_features set label = 'Détection des sujets chauds'         where key = 'inspiration.hot_topics';
update public.elocia_features set label = 'Digest de veille hebdomadaire'       where key = 'inspiration.weekly_digest';
update public.elocia_features set label = 'Validation en un clic'               where key = 'inspiration.validate';
update public.elocia_features set label = 'Alerte de rythme de publication'     where key = 'calendrier.alert_rythme';
update public.elocia_features set label = 'Planning éditorial du mois'          where key = 'calendrier.file_editoriale';
update public.elocia_features set label = 'Découverte de temps forts par l''IA' where key = 'tempsforts.discover_ai';
update public.elocia_features set label = 'Marronniers du secteur'             where key = 'tempsforts.marronniers';
update public.elocia_features set label = 'Frise éditoriale'                    where key = 'tempsforts.timeline';
update public.elocia_features set label = 'Construction d''angle par l''IA'     where key = 'labo.build_angle';
update public.elocia_features set label = 'Envoi vers le Générateur'            where key = 'labo.push_to_rediger';
update public.elocia_features set label = 'Visuel suggéré automatiquement'      where key = 'rediger.visual_narro';
update public.elocia_features set label = 'Sources pré-sélectionnées par secteur' where key = 'params.curated_sources';
update public.elocia_features set label = 'Ajout rapide depuis Google News'     where key = 'params.google_news';
update public.elocia_features set label = 'Bouton de retour flottant'           where key = 'widget.feedback';
