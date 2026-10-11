-- 0069 : cartes d'action « à faire pour la responsable produit ».
--
-- L'agent traite seul ce qu'il peut. Quand il a besoin de Marion (valider un plan,
-- exécuter du SQL, poser une variable, répondre à une question, regarder un
-- résultat), il dépose une CARTE D'ACTION clé en main. Marion répond d'un clic,
-- l'agent reprend la main au passage suivant.
-- Nouveau statut d'idée « on_dev » (fusionné dans dev, à tester sur le staging).
-- Idempotente : réexécutable sans risque.

create table if not exists public.elocia_improvement_actions (
  id             uuid primary key default gen_random_uuid(),
  created_at     timestamptz not null default now(),
  improvement_id uuid not null references public.elocia_improvements(id) on delete cascade,
  kind           text not null check (kind in ('plan','sql','config','question','preview')),
  status         text not null default 'open'
                 check (status in ('open','approved','rejected','done','answered','dismissed')),
  round          int  not null default 1,
  title          text not null check (char_length(title) between 1 and 200),
  body           text,
  payload        jsonb not null default '{}'::jsonb,
  response       jsonb,
  responded_at   timestamptz,
  handled_at     timestamptz
);

create index if not exists elocia_improvement_actions_idx
  on public.elocia_improvement_actions (status, created_at desc);
create index if not exists elocia_improvement_actions_idea_idx
  on public.elocia_improvement_actions (improvement_id);

alter table public.elocia_improvement_actions enable row level security;

drop policy if exists improvement_actions_read on public.elocia_improvement_actions;
create policy improvement_actions_read on public.elocia_improvement_actions
  for select to authenticated
  using (public.narro_current_role() = 'super_admin');

drop policy if exists improvement_actions_update on public.elocia_improvement_actions;
create policy improvement_actions_update on public.elocia_improvement_actions
  for update to authenticated
  using (public.narro_current_role() = 'super_admin')
  with check (public.narro_current_role() = 'super_admin');

grant select, update on public.elocia_improvement_actions to authenticated;

alter table public.elocia_improvements
  drop constraint if exists elocia_improvements_status_check;
alter table public.elocia_improvements
  add constraint elocia_improvements_status_check
  check (status in ('new','triaged','needs_framing','decided','in_pr','on_dev','validated','shipped','rejected'));

notify pgrst, 'reload schema';
