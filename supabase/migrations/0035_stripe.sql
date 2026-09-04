-- 0035 : integration Stripe (test + prod).
--
-- Mappings entre nos plans et Stripe : chaque plan pointe vers un
-- price_id Stripe (test dans un premier temps, prod quand on bascule).
-- Chaque profil garde son customer_id Stripe et l'id de son abonnement
-- actif, plus le statut (active | past_due | canceled | trialing | ...).

ALTER TABLE public.elocia_plans
  ADD COLUMN IF NOT EXISTS stripe_price_id text;

ALTER TABLE public.elocia_profiles
  ADD COLUMN IF NOT EXISTS stripe_customer_id text UNIQUE,
  ADD COLUMN IF NOT EXISTS stripe_subscription_id text,
  ADD COLUMN IF NOT EXISTS subscription_status text,
  ADD COLUMN IF NOT EXISTS current_period_end timestamptz;

-- Index pour retrouver rapidement un profil depuis un customer Stripe
-- (utile dans le webhook Stripe).
CREATE INDEX IF NOT EXISTS elocia_profiles_stripe_customer_idx
  ON public.elocia_profiles (stripe_customer_id)
  WHERE stripe_customer_id IS NOT NULL;
