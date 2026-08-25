-- 0055 : retrait du digest hebdomadaire « A retenir cette semaine »
--
-- CONTEXTE : le digest et les 5 suggestions Inspiration etaient generes le
--   MEME lundi, a partir de la MEME veille, par deux appels IA distincts, et
--   faisaient le meme travail — choisir les sujets qui meritent une prise de
--   parole. La difference : les suggestions vont jusqu'au bout (le post est
--   redige), le digest s'arretait au titre. Il occupait en plus le haut de la
--   page d'accueil, repoussant sous la ligne de flottaison ce que le produit
--   vend vraiment.
--
--   Meme diagnostic que les « hot topics » (migration 0050) : genere chaque
--   semaine, paye chaque semaine, sans usage reel.
--
-- APRES : le cron /api/cron/weekly-digest, le bloc d'accueil, la generation
--   et la cle de fonctionnalite disparaissent. La cle etait deja masquee de
--   la matrice d'offres par la migration 0051 (is_active = false) ; on la
--   supprime pour de bon.
--
-- LA TABLE elocia_weekly_digests EST CONSERVEE. Elle contient l'historique
--   deja genere ; la supprimer serait une perte irreversible pour un gain nul
--   (plus personne n'ecrit dedans). A dropper plus tard si on la confirme
--   inutile.
--
-- Idempotent.

delete from public.elocia_plan_features
  where feature_key = 'inspiration.weekly_digest';

delete from public.elocia_features
  where key = 'inspiration.weekly_digest';
