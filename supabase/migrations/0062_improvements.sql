-- 0062 : retours « améliorations » de l'équipe (admins) — distincts des bugs.
--
-- Les BUGS restent dans elocia_user_feedback (bouton « Signaler un bug »).
-- Les IDÉES / AMÉLIORATIONS vont ici, avec un cycle de vie piloté par l'agent
-- (tri, PR vers la branche dev) et un fil de commentaires.
-- Idempotente : réexécutable sans risque.

create table if not exists public.elocia_improvements (
  id            uuid primary key default gen_random_uuid(),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  profile_id    uuid not null references public.elocia_profiles(id) on delete cascade,
  author_name   text,
  message       text not null check (char_length(message) between 1 and 5000),
  kind          text not null default 'idee'
                check (kind in ('idee','texte','design','autre')),
  -- Cycle de vie : new -> triaged | needs_framing -> in_pr -> validated -> shipped | rejected
  status        text not null default 'new'
                check (status in ('new','triaged','needs_framing','in_pr','validated','shipped','rejected')),
  -- Contexte capturé automatiquement
  page_path     text,
  page_title    text,
  user_agent    text,
  viewport      text,
  via_voice     boolean not null default false,
  -- Pièces jointes (bucket narro-feedback, préfixe improvements/)
  screenshot_path text,
  attachments   jsonb not null default '[]'::jsonb,   -- [{path,name,type,size}]
  -- Renseigné par l'agent
  difficulty    text check (difficulty in ('easy','complex')),
  agent_summary text,
  agent_proposal text,
  pr_url        text,
  preview_url   text
);

create index if not exists elocia_improvements_status_idx
  on public.elocia_improvements (status, created_at desc);

create table if not exists public.elocia_improvement_comments (
  id             uuid primary key default gen_random_uuid(),
  created_at     timestamptz not null default now(),
  improvement_id uuid not null references public.elocia_improvements(id) on delete cascade,
  profile_id     uuid references public.elocia_profiles(id) on delete set null,
  author_name    text,
  is_agent       boolean not null default false,
  body           text not null check (char_length(body) between 1 and 3000)
);

create index if not exists elocia_improvement_comments_idx
  on public.elocia_improvement_comments (improvement_id, created_at);

alter table public.elocia_improvements enable row level security;
alter table public.elocia_improvement_comments enable row level security;

-- Fonctionnalité de développement : réservée aux super-admins.
-- Lecture : les super-admins voient tout.
drop policy if exists improvements_read on public.elocia_improvements;
create policy improvements_read on public.elocia_improvements
  for select to authenticated
  using (public.narro_current_role() = 'super_admin');

-- Création : on n'écrit qu'en son nom.
drop policy if exists improvements_insert on public.elocia_improvements;
create policy improvements_insert on public.elocia_improvements
  for insert to authenticated
  with check (
    public.narro_current_role() = 'super_admin'
    and profile_id = auth.uid()
  );

-- Modification (statut, notes de l'agent) : super-admin.
-- L'agent passe par la clé service_role (qui ignore le RLS).
drop policy if exists improvements_update on public.elocia_improvements;
create policy improvements_update on public.elocia_improvements
  for update to authenticated
  using (public.narro_current_role() = 'super_admin')
  with check (public.narro_current_role() = 'super_admin');

drop policy if exists improvements_delete on public.elocia_improvements;
create policy improvements_delete on public.elocia_improvements
  for delete to authenticated
  using (public.narro_current_role() = 'super_admin');

drop policy if exists improvement_comments_read on public.elocia_improvement_comments;
create policy improvement_comments_read on public.elocia_improvement_comments
  for select to authenticated
  using (public.narro_current_role() = 'super_admin');

drop policy if exists improvement_comments_insert on public.elocia_improvement_comments;
create policy improvement_comments_insert on public.elocia_improvement_comments
  for insert to authenticated
  with check (
    public.narro_current_role() = 'super_admin'
    and profile_id = auth.uid()
    and is_agent = false
  );

grant select, insert, update, delete on public.elocia_improvements to authenticated;
grant select, insert on public.elocia_improvement_comments to authenticated;
