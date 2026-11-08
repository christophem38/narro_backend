-- 0077 : historique des sondes de santé (page « Statut Production »).
--
-- Une ligne par service et par passage (toutes les 10 min, cron
-- /api/cron/sante). L'état affiché = la dernière ligne de chaque service.
-- Table réservée au service (RLS activé, aucune politique) : seule la clé
-- service-role la lit et l'écrit, jamais le navigateur.
-- Idempotente : réexécutable sans risque.

create table if not exists public.elocia_health_checks (
  id          bigint generated always as identity primary key,
  checked_at  timestamptz not null default now(),
  service     text not null,
  ok          boolean not null,
  latency_ms  integer,
  detail      text
);

create index if not exists elocia_health_checks_service_idx
  on public.elocia_health_checks (service, checked_at desc);

alter table public.elocia_health_checks enable row level security;
