-- 0023 : ecriture inclusive (oui/non)
--
-- Ajoute la preference d'ecriture inclusive au profil. Nullable pour
-- retro-compatibilite : les comptes existants n'ont pas la valeur, le
-- code applicatif utilise false par defaut.

ALTER TABLE narro_profiles
ADD COLUMN IF NOT EXISTS inclusive_writing BOOLEAN;
