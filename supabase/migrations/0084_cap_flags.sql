-- 0084 : DRAPEAUX sur Mon cap (3 au maximum). Une info facultative marquée d'un
-- drapeau est traitée au même niveau de priorité que les infos de l'onboarding.
-- cartes ajoutées : colonne flagged ; rubriques de base facultatives : liste de clés
-- (priorite, territoires, messages, preuves) sur le profil. Idempotente.
alter table public.elocia_cap_cards
  add column if not exists flagged boolean not null default false;
alter table public.elocia_profiles
  add column if not exists cap_flagged_cards text[] not null default '{}';
