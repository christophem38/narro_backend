-- 0066 : SÉCURITÉ — protection des colonnes privilégiées de elocia_profiles
--
-- Faille corrigée (audit 2026-09-03, bloc A5) : la policy RLS self_update
-- autorise `id = auth.uid()`, mais PostgreSQL RLS filtre par ligne, pas
-- par colonne. Un client pouvait donc exécuter :
--   UPDATE elocia_profiles SET role = 'super_admin' WHERE id = auth.uid();
--
-- Après : un trigger BEFORE UPDATE bloque toute modification de :
--   role, subscription_tier, team_id, stripe_customer_id, stripe_subscription_id,
--   subscription_status, current_period_end, email
-- pour toute session dont auth.uid() correspond à un profil qui n'est PAS
-- admin/super_admin. Le service_role (auth.uid() IS NULL) et les
-- admins/super_admins conservent l'accès complet.
--
-- Callers légitimes déjà audités :
--   - lib/actions.ts updateSubscriptionTier → check applicatif super_admin
--   - lib/actions.ts setUserTeam           → service_role
--   - app/api/stripe/*                     → service_role
--   - trigger handle_new_user              → service_role au moment de l'INSERT

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
  IF my_role IN ('admin', 'super_admin') THEN
    RETURN NEW;
  END IF;

  IF NEW.role IS DISTINCT FROM OLD.role THEN
    RAISE EXCEPTION 'not allowed to change role';
  END IF;
  IF NEW.subscription_tier IS DISTINCT FROM OLD.subscription_tier THEN
    RAISE EXCEPTION 'not allowed to change subscription_tier';
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
  IF NEW.email IS DISTINCT FROM OLD.email THEN
    RAISE EXCEPTION 'not allowed to change email';
  END IF;

  RETURN NEW;
END
$function$;

DROP TRIGGER IF EXISTS narro_guard_profile_privileged ON public.elocia_profiles;
CREATE TRIGGER narro_guard_profile_privileged
BEFORE UPDATE ON public.elocia_profiles
FOR EACH ROW
EXECUTE FUNCTION public.narro_guard_profile_privileged_columns();
