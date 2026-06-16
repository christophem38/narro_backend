-- 0017_feedback_workflow.sql
-- Workflow elargi pour les retours utilisateurs :
-- - 4 statuts pilotables : new / analysed / todo / done
-- - recapitulation : ce que l'admin a compris du besoin avant de coder
-- - questions : liste de questions soulevees par l'analyse, avec reponses
-- 2026-06-15

-- 1) Remplacer le check constraint pour accepter les nouveaux statuts
alter table public.narro_user_feedback
  drop constraint if exists narro_user_feedback_status_check;

-- 2) Backfill : projeter les anciens statuts vers les nouveaux
update public.narro_user_feedback set status = 'new'
  where status = 'open';
update public.narro_user_feedback set status = 'analysed'
  where status = 'in_progress';
update public.narro_user_feedback set status = 'done'
  where status in ('resolved', 'wontfix');

-- 3) Nouveau check + nouvelle valeur par defaut
alter table public.narro_user_feedback
  add constraint narro_user_feedback_status_check
  check (status in ('new', 'analysed', 'todo', 'done'));

alter table public.narro_user_feedback
  alter column status set default 'new';

-- 4) Nouvelles colonnes
alter table public.narro_user_feedback
  add column if not exists recapitulation text,
  add column if not exists questions      jsonb not null default '[]'::jsonb;

-- 5) Forcer toutes les questions a la structure attendue : tableau
update public.narro_user_feedback
  set questions = '[]'::jsonb
  where jsonb_typeof(questions) is distinct from 'array';

-- Structure d'une entree dans questions :
--   { "id": "uuid", "question": "...", "answer": "...|null",
--     "created_at": "timestamptz", "answered_at": "timestamptz|null" }
