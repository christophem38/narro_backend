-- 0030 : stockage de l'import LinkedIn sanitisé
--
-- L'utilisateur peut déposer son export LinkedIn (.zip) sur la page Profil.
-- Le serveur (app/api/profile/linkedin-import) le trie via une allowlist
-- stricte et ne persiste QUE le résultat sanitisé (aucune donnée sensible :
-- messages, téléphone, reçus, e-mails de tiers ne sont jamais lus/stockés).
--
-- On stocke ce résultat en jsonb sur le profil. RLS déjà en place sur
-- elocia_profiles (self_update : id = auth.uid()).

alter table public.elocia_profiles
  add column if not exists linkedin_import    jsonb,
  add column if not exists linkedin_import_at timestamptz;
