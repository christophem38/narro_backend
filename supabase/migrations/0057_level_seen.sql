-- Dernier niveau d'autorité éditoriale « vu » par l'utilisateur.
-- Sert à ne célébrer un passage de niveau qu'UNE SEULE FOIS par compte (et non
-- à chaque chargement de page, le niveau étant recalculé à la volée depuis les
-- posts publiés). NULL = jamais célébré : on initialise au niveau courant sans
-- animation, pour ne pas fêter rétroactivement les niveaux déjà atteints.
alter table public.elocia_profiles
  add column if not exists level_seen integer;
