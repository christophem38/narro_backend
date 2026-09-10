-- 0068 : réservation de démo depuis la landing
--
-- Une ligne par demande : email validé par code, puis créneau réservé.
-- Le jeton (généré côté serveur) sert aux liens « choisir un autre créneau »
-- envoyés après une annulation par l'admin. Table sans policy : seul le
-- service_role (routes API et actions super-admin) y accède.
--
-- Les disponibilités (plages hebdomadaires, durée, délai minimum, horizon,
-- lien Google Meet, jours fermés) vivent dans elocia_admin_settings sous la
-- clé `demo_settings`, modifiables depuis /super-admin/demos.

create table if not exists public.elocia_demo_bookings (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  name text,
  company text,
  status text not null default 'pending' check (status in ('pending', 'booked', 'cancelled')),
  verify_code_hash text,
  code_expires_at timestamptz,
  code_attempts integer not null default 0,
  email_verified_at timestamptz,
  token text not null unique,
  slot_start timestamptz,
  slot_end timestamptz,
  meet_link text,
  cancelled_at timestamptz,
  ip text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.elocia_demo_bookings enable row level security;

-- Un seul rendez-vous confirmé par créneau.
create unique index if not exists elocia_demo_bookings_slot_booked
  on public.elocia_demo_bookings (slot_start) where status = 'booked';

create index if not exists elocia_demo_bookings_email_created
  on public.elocia_demo_bookings (email, created_at desc);

insert into public.elocia_admin_settings (key, value, updated_at)
values (
  'demo_settings',
  '{"slot_minutes":30,"lead_hours":24,"horizon_days":21,"meet_link":"","weekly":{"2":[["14:00","17:00"]],"4":[["14:00","17:00"]]},"closed_days":[]}'::jsonb,
  now()
)
on conflict (key) do nothing;
