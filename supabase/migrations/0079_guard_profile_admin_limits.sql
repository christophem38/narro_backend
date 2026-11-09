-- 0079 : SÉCURITÉ — resserre le garde des colonnes privilégiées (suite de 0066).
--
-- Audit 2026-11-08 (A5, MAJEUR) : le trigger de 0066 laissait un compte
-- « admin » modifier, sur sa propre ligne, son offre, son équipe et ses
-- identifiants Stripe. Désormais :
--
--   service_role / super_admin : tout (inchangé)
--   admin   : peut changer subscription_tier (l'outil « tester une offre »
--             de setSubscriptionTier, lib/actions.ts) et son email ;
--             NE PEUT PLUS changer team_id, stripe_customer_id,
--             stripe_subscription_id, subscription_status, current_period_end,
--             trial_started_at, ni role (déjà protégé par la policy)
--   client  : comme avant, plus trial_started_at (remettre l'essai à zéro
--             permettait de le redemander ; seul le webhook Stripe l'écrit,
--             en service_role)
--
-- Callers audités : setUserTeam → service_role ; app/api/stripe/* → service_role ;
-- setSubscriptionTier → admin sur subscription_tier + subscription_started_at.
--
-- RETOUR ARRIÈRE : ré-exécuter 0066 (recrée la fonction précédente).
-- Idempotente.

CREATE OR REPLACE FUNCTION public.narro_guard_profile_privileged_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  my_role text;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT role INTO my_role FROM public.elocia_profiles WHERE id = auth.uid();
  IF my_role = 'super_admin' THEN
    RETURN NEW;
  END IF;

  -- Interdits à tout non super-admin (admin compris).
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    RAISE EXCEPTION 'not allowed to change role';
  END IF;
  IF NEW.team_id IS DISTINCT FROM OLD.team_id THEN
    RAISE EXCEPTION 'not allowed to change team_id';
  END IF;
  IF NEW.stripe_customer_id IS DISTINCT FROM OLD.stripe_customer_id THEN
    RAISE EXCEPTION 'not allowed to change stripe_customer_id';
  END IF;
  IF NEW.stripe_subscription_id IS DISTINCT FROM OLD.stripe_subscription_id THEN
    RAISE EXCEPTION 'not allowed to change stripe_subscription_id';
  END IF;
  IF NEW.subscription_status IS DISTINCT FROM OLD.subscription_status THEN
    RAISE EXCEPTION 'not allowed to change subscription_status';
  END IF;
  IF NEW.current_period_end IS DISTINCT FROM OLD.current_period_end THEN
    RAISE EXCEPTION 'not allowed to change current_period_end';
  END IF;
  IF NEW.trial_started_at IS DISTINCT FROM OLD.trial_started_at THEN
    RAISE EXCEPTION 'not allowed to change trial_started_at';
  END IF;

  -- Un admin garde l'offre (outil de test) et l'email ; un client non.
  IF my_role IS DISTINCT FROM 'admin' THEN
    IF NEW.subscription_tier IS DISTINCT FROM OLD.subscription_tier THEN
      RAISE EXCEPTION 'not allowed to change subscription_tier';
    END IF;
    IF NEW.email IS DISTINCT FROM OLD.email THEN
      RAISE EXCEPTION 'not allowed to change email';
    END IF;
  END IF;

  RETURN NEW;
END
$function$;

-- Le trigger de 0066 existe déjà et appelle cette fonction par son nom : rien à recréer.
