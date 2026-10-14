-- 0070 : événements produit (monitoring des usages).
--
-- Une ligne par geste utile à mesurer. Premiers événements suivis :
--   coach_mode_chosen    : après la génération, la personne choisit comment être
--                          accompagnée (props.mode = 'parcours' | 'agent')
--   coach_mode_switched  : elle change de mode en cours de route (from, to)
--   coach_finished       : elle valide son texte (mode, score_start, score_end,
--                          duration_sec, ai_calls, steps, angles)
--   quota_upsell_shown   : la limite d'actions IA du jour a été atteinte et la
--                          fenêtre d'offres s'est ouverte (kind)
-- Lus par la page « Statistiques » du superadmin (/super-admin/stats).
--
-- Écriture : les actions serveur tournent en tant que l'utilisateur (comme pour
-- elocia_ai_calls). Lecture : superadmin uniquement. Idempotente.

create table if not exists public.elocia_product_events (
  id         uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  profile_id uuid references public.elocia_profiles(id) on delete cascade,
  event      text not null check (char_length(event) between 1 and 60),
  props      jsonb not null default '{}'::jsonb
);

create index if not exists elocia_product_events_event_idx
  on public.elocia_product_events (event, created_at desc);
create index if not exists elocia_product_events_profile_idx
  on public.elocia_product_events (profile_id, created_at desc);

alter table public.elocia_product_events enable row level security;

drop policy if exists product_events_read on public.elocia_product_events;
create policy product_events_read on public.elocia_product_events
  for select to authenticated
  using (public.narro_current_role() = 'super_admin');

drop policy if exists product_events_insert on public.elocia_product_events;
create policy product_events_insert on public.elocia_product_events
  for insert to authenticated
  with check (profile_id = auth.uid());

grant select, insert on public.elocia_product_events to authenticated;

notify pgrst, 'reload schema';
