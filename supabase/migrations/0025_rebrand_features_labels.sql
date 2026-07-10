-- 0025 : rebrand Narro -> Elocia dans les labels/descriptions de features
--
-- La migration 0016 avait insere trois features avec "Narro" dans leur
-- label ou description ; ces textes sont affiches dans la matrice des
-- plans (super-admin) et dans certains messages utilisateur.

UPDATE public.elocia_features
   SET description = 'Construction de l''angle Elocia'
 WHERE key = 'labo.build_angle';

UPDATE public.elocia_features
   SET label = 'Visuel suggere par Elocia'
 WHERE key = 'rediger.visual_narro';

UPDATE public.elocia_features
   SET description = 'Colonne droite + Elocia suggestions'
 WHERE key = 'tempsforts.timeline';
