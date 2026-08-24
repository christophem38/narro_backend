-- Guide de première visite du Générateur (GeneratorTour) : mémorisé PAR COMPTE.
-- Avant, l'état « déjà vu » ne vivait que dans le localStorage du navigateur, si
-- bien que le guide réapparaissait sur un autre appareil, en navigation privée
-- ou après un vidage de cache. On le rattache donc au profil.
-- Valeur = date à laquelle l'utilisateur a vu OU passé le guide ; null = jamais.
alter table public.elocia_profiles
  add column if not exists tour_generator_seen_at timestamptz;
