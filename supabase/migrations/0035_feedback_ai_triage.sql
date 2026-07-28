-- 0035_feedback_ai_triage.sql
-- Tri automatique des retours par l'IA (Niveau 1) :
-- - request_type : nature de la demande, choisie par l'utilisateur puis
--   confirmee par l'IA (bug / amelioration / texte / autre)
-- - ai_size       : taille estimee du chantier (S / M / L)
-- - ai_difficulty : difficulte estimee (facile / moyen / difficile)
-- - ai_triaged_at : horodatage du dernier passage IA
-- La reformulation ("recapitulation") et les "questions" existent deja
-- (migration 0017) : l'IA les remplit automatiquement.
-- Ajoute aussi le statut 'rejected' (demande refusee apres validation).
-- 2026-07-28

alter table public.elocia_user_feedback
  add column if not exists request_type  text,
  add column if not exists ai_size        text,
  add column if not exists ai_difficulty  text,
  add column if not exists ai_triaged_at  timestamptz;

-- Elargir les statuts pour accepter 'rejected'. Le nom du check date d'avant
-- le rebrand narro -> elocia (0024) ; on tente les deux noms possibles.
alter table public.elocia_user_feedback
  drop constraint if exists narro_user_feedback_status_check;
alter table public.elocia_user_feedback
  drop constraint if exists elocia_user_feedback_status_check;
alter table public.elocia_user_feedback
  add constraint elocia_user_feedback_status_check
  check (status in ('new', 'analysed', 'todo', 'done', 'rejected'));
