-- 0061 : SÉCURITÉ — ownership check sur narro_seed_progress_plan
--
-- Faille corrigée (audit 2026-09-03, bloc A6) : n'importe quel authenticated
-- pouvait faire `select public.narro_seed_progress_plan('<uuid autre user>')`
-- car la fonction est SECURITY DEFINER + accepte un p_profile_id sans vérif.
-- Impact : DELETE puis re-INSERT des tâches de progression de la victime.
--
-- Après : trois contextes légitimes seulement :
--   1. auth.uid() IS NULL — appel serveur / trigger interne (backfill, etc.)
--   2. p_profile_id = auth.uid() — l'user pour lui-même
--   3. l'appelant est admin ou super_admin
--
-- Callers connus : trigger narro_on_profile_insert (auto-seed à la création
-- d'un profil ; auth.uid() = new.id à ce moment-là, cas 2).

CREATE OR REPLACE FUNCTION public.narro_seed_progress_plan(p_profile_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  IF p_profile_id IS NULL THEN
    RAISE EXCEPTION 'p_profile_id required';
  END IF;

  IF auth.uid() IS NOT NULL THEN
    IF p_profile_id <> auth.uid()
       AND NOT EXISTS (
         SELECT 1 FROM public.elocia_profiles
         WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
       )
    THEN
      RAISE EXCEPTION 'forbidden: cannot seed progress plan for another user';
    END IF;
  END IF;

  DELETE FROM public.elocia_progress_tasks WHERE profile_id = p_profile_id;
  INSERT INTO public.elocia_progress_tasks (profile_id, month_index, ordinal, title) VALUES
    (p_profile_id, 1, 0, 'Réagir à une actualité de votre secteur'),
    (p_profile_id, 1, 1, 'Commenter une tendance émergente'),
    (p_profile_id, 1, 2, 'Partager un apprentissage simple'),
    (p_profile_id, 1, 3, 'Installer un rythme : 1 post / semaine'),
    (p_profile_id, 2, 0, 'Analyse marché : poser un point de vue'),
    (p_profile_id, 2, 1, 'Retour d''expérience sur un projet récent'),
    (p_profile_id, 2, 2, 'Décrypter un sujet sectoriel'),
    (p_profile_id, 2, 3, 'Passer à 2 posts / semaine'),
    (p_profile_id, 3, 0, 'Opinion personnelle assumée sur un sujet clivant'),
    (p_profile_id, 3, 1, 'Leadership sectoriel : proposer une vision'),
    (p_profile_id, 3, 2, 'Vision long terme : raconter votre cap'),
    (p_profile_id, 3, 3, 'Tenir 2-3 posts / semaine');
END
$function$;
