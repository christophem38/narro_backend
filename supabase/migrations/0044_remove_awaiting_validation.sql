-- Suppression de l'étape « À relire ».
--
-- Pourquoi : c'était une AUTO-relecture. Le même profil envoyait le post à
-- relire et l'approuvait ensuite — deux clics de friction avant la première
-- récompense, pour une étape que personne d'autre ne réalisait. Le libellé
-- « à valider » laissait même croire qu'un tiers devait approuver.
--
-- Le cycle passe de 5 à 4 étapes :
--     Brouillon → Validé (daté ou non) → Publié
--
-- Les posts qui attendaient une relecture RETOMBENT EN BROUILLON : c'est là
-- qu'on peut les reprendre, les valider ou les programmer directement. On ne
-- les passe pas en « validé » d'office — ils n'ont jamais été relus, et les
-- promouvoir sans lecture serait décider à la place de l'utilisateur.
--
-- Le contrôle de conformité (garde-fous de la bibliothèque de marque) n'est
-- pas perdu : il se fait désormais sur les cartes Validés / Programmés.
--
-- Rejouable : sans ligne concernée, l'UPDATE ne fait rien.

update public.elocia_suggested_posts
  set status = 'draft',
      updated_at = now()
  where status = 'awaiting_validation';
