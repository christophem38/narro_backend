-- Matrice des offres : masquer les fonctionnalités qui ne font rien.
--
-- CONSTAT : le catalogue compte 32 fonctionnalités, mais SEULES 11 sont
-- réellement vérifiées dans le code. Les 20 autres (hot_topics ayant été
-- retirée en 0050) sont des interrupteurs décoratifs : les activer ou les
-- désactiver dans la matrice du Super Admin ne change strictement rien pour
-- l'utilisateur.
--
-- C'est pire qu'inutile : en configurant une offre, on croit retirer un droit
-- qui reste en réalité accordé. C'est exactement ce qui faisait croire que la
-- détection IA des temps forts était réservée à Pro, alors que Solo l'avait.
--
-- Le contrôle réel se fait au niveau de la PAGE (clés « .view »), pas de
-- l'action. Tant qu'une clé fine n'est pas branchée dans le code, elle n'a
-- rien à faire dans un écran de configuration.
--
-- CHOIX : on MASQUE (is_active = false) plutôt que de supprimer. Rien n'est
-- perdu — le jour où l'une de ces clés est réellement implémentée, il suffit
-- de la repasser à true pour qu'elle réapparaisse dans la matrice. Les
-- rattachements aux offres (elocia_plan_features) sont conservés intacts.
--
-- AUCUN CHANGEMENT DE DROITS : fetchUserFeatures lit elocia_plan_features, que
-- cette migration ne touche pas. Personne ne gagne ni ne perd d'accès.

update public.elocia_features
  set is_active = false,
      updated_at = now()
  where key in (
    -- Inspiration : la page est gardée par inspiration.view, pas ces clés.
    'inspiration.generate_ai',
    'inspiration.validate',
    'inspiration.weekly_digest',
    -- Rebond éditorial
    'labo.build_angle',
    'labo.push_to_rediger',
    -- Générateur
    'rediger.generate_post',
    'rediger.visual_narro',
    'rediger.visual_upload',
    -- Calendrier
    'calendrier.file_editoriale',
    -- Temps forts : `discover_ai` était censé être un différenciateur Pro,
    -- mais le cron le donne à tout profil ayant tempsforts.view (donc Solo).
    -- Décision produit : les temps forts restent inclus en Solo.
    'tempsforts.add_manual',
    'tempsforts.discover_ai',
    'tempsforts.marronniers',
    'tempsforts.timeline',
    -- Relecture : seule avalider.view est vérifiée (migration 0049).
    'avalider.publish',
    -- Pages atteignables via Objectifs / Mon compte, qui sont universels.
    'strategie.view',
    'bibliotheque.view',
    -- Sources : la page est gardée par inspiration.view.
    'params.feeds',
    'params.curated_sources',
    'params.google_news',
    'params.linkedin'
  );
