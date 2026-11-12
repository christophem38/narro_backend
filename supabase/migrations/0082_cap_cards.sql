-- 0082 : CARTES « MON CAP » — informations en texte libre ajoutées via le « + »
-- de la page Mon cap (expressions, histoire, convictions, « ce que je refuse de
-- dire », offres, clients types…). Elles alimentent la génération des posts et le
-- coach (lib/cap-cards.ts décide où chaque type arrive dans le prompt).
--
-- Une ligne = une carte. Plusieurs cartes du même type sont permises.
-- RLS : chacun ne voit et ne modifie que ses propres cartes.
-- RETOUR ARRIÈRE : drop table public.elocia_cap_cards;  Idempotente.

create table if not exists public.elocia_cap_cards (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.elocia_profiles(id) on delete cascade,
  kind text not null check (kind in (
    'expressions', 'histoire', 'convictions', 'refus',
    'offres', 'clients_types', 'idees_recues', 'concurrents',
    'formats', 'rendez_vous', 'appels_action', 'evenements',
    'valeurs', 'marque', 'ambassadeurs'
  )),
  content text not null default '' check (char_length(content) <= 1500),
  display_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists elocia_cap_cards_profile_idx
  on public.elocia_cap_cards (profile_id, display_order);

alter table public.elocia_cap_cards enable row level security;

drop policy if exists self_all on public.elocia_cap_cards;
create policy self_all on public.elocia_cap_cards
  for all to authenticated
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());
