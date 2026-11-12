-- 0083 : rubriques de « Mon cap » retirées par l'utilisateur (petite croix au survol).
-- Les rubriques issues de l'onboarding (cap, rythme, objectifs, audiences) restent
-- obligatoires ; les autres (priorité 90 jours, sujets, idées à répéter, preuves)
-- peuvent être retirées puis rajoutées via le « + ». Clés : priorite, territoires,
-- messages, preuves. Idempotente.
alter table public.elocia_profiles
  add column if not exists cap_hidden_cards text[] not null default '{}';
