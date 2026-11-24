-- 0093 : préférences d'emails non essentiels (désinscription).
--
-- Deux catégories, choisies par la personne via le lien « Ne plus recevoir » :
--   - relation : bilans mensuels, nouveautés (maquettes E10, E28) ;
--   - offers   : offres commerciales, reconquête (maquette E24).
-- Les emails de service (confirmation, mot de passe, facturation, sécurité,
-- suppression de compte) ne sont JAMAIS concernés : on ne peut pas s'en désabonner.
--
-- Idempotente : peut être rejouée sans effet.

alter table public.elocia_profiles
  add column if not exists email_optout_relation boolean not null default false,
  add column if not exists email_optout_offers boolean not null default false;

comment on column public.elocia_profiles.email_optout_relation is
  'true = la personne ne veut plus des emails de relation (bilans, nouveautés).';
comment on column public.elocia_profiles.email_optout_offers is
  'true = la personne ne veut plus des emails d''offres commerciales.';
