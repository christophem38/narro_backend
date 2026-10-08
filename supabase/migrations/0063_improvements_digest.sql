-- 0063 : récap quotidien des idées complexes + décision de la responsable produit.
--
-- L'agent reformule chaque idée à recadrer (titre, résumé, options, recommandation,
-- questions) ; Marion tranche (décision) puis l'agent implémente au passage suivant.
-- Nouveau statut « decided ». Idempotente : réexécutable sans risque.

alter table public.elocia_improvements
  add column if not exists digest_title          text,
  add column if not exists digest_summary        text,
  add column if not exists digest_group          text,
  add column if not exists digest_options        jsonb not null default '[]'::jsonb,  -- [{label,description,effort,risks}]
  add column if not exists digest_recommendation text,
  add column if not exists digest_questions      jsonb not null default '[]'::jsonb,  -- ["…"]
  add column if not exists digested_at           timestamptz,
  add column if not exists decision              text,
  add column if not exists decided_at            timestamptz;

alter table public.elocia_improvements
  drop constraint if exists elocia_improvements_status_check;
alter table public.elocia_improvements
  add constraint elocia_improvements_status_check
  check (status in ('new','triaged','needs_framing','decided','in_pr','validated','shipped','rejected'));

notify pgrst, 'reload schema';
