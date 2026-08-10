-- Cockpit superadmin des API externes : réglages (plafond de budget IA mensuel).
-- Accès réservé au service-role : les server actions superadmin écrivent/lisent
-- via la clé service-role. RLS activée SANS policy publique → aucun accès direct
-- depuis le client authentifié.

create table if not exists public.elocia_admin_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.elocia_admin_settings enable row level security;

-- Valeur par défaut du budget IA mensuel (modifiable depuis le cockpit).
insert into public.elocia_admin_settings (key, value)
values ('ai_budget', '{"monthly_usd": 50}'::jsonb)
on conflict (key) do nothing;
