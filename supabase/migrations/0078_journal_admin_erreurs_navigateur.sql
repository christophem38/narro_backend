-- 0078 : journal d'administration + erreurs du navigateur.
--
-- Deux tables réservées au service (RLS activé, aucune politique) : seule la
-- clé service-role les lit et les écrit, jamais le navigateur.
-- Idempotente : réexécutable sans risque.

-- Qui a changé quoi (rôles, budget IA, fournisseurs, prompts, prise de contrôle…).
create table if not exists public.elocia_admin_journal (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  actor_id    uuid,
  actor_email text,
  action      text not null,
  cible       text,
  detail      jsonb
);
create index if not exists elocia_admin_journal_date_idx
  on public.elocia_admin_journal (created_at desc);
alter table public.elocia_admin_journal enable row level security;

-- Erreurs JavaScript vues dans le navigateur des utilisateurs.
create table if not exists public.elocia_browser_errors (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  empreinte   text not null,
  message     text not null,
  pile        text,
  page        text,
  user_agent  text
);
create index if not exists elocia_browser_errors_date_idx
  on public.elocia_browser_errors (created_at desc);
create index if not exists elocia_browser_errors_empreinte_idx
  on public.elocia_browser_errors (empreinte, created_at desc);
alter table public.elocia_browser_errors enable row level security;
