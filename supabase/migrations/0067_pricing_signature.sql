-- 0067 : nouvelle grille tarifaire (septembre 2026)
--
-- Landing refondue : Solo 29 € HT/mois (290 €/an), Signature 59 € HT/mois
-- (590 €/an), Équipe sur contact. Essai 7 jours avec carte bancaire, le plan
-- gratuit disparaît de l'offre publique.
--
-- 1. Colonnes : prix annuel, price Stripe annuel, jours d'essai par plan,
--    date de début d'essai par profil (un seul essai par compte).
-- 2. Renommage de la clé `pro` en `signature` (plans, matrice, profils,
--    contrainte CHECK des profils).
-- 3. Prix, libellés, bénéfices, visibilité.
-- 4. Comptes gratuits existants : basculés sur Signature en essai 7 jours.

-- 1. Colonnes ---------------------------------------------------------------
alter table public.elocia_plans
  add column if not exists price_eur_yearly numeric,
  add column if not exists stripe_price_id_yearly text,
  add column if not exists trial_days integer not null default 0;

alter table public.elocia_profiles
  add column if not exists trial_started_at timestamptz;

-- 2. pro -> signature ---------------------------------------------------------
insert into public.elocia_plans (key, label, description, price_eur_monthly, oneshot,
  is_active, is_visible, highlight, display_order, highlights, stripe_price_id, created_at, updated_at)
select 'signature', 'Signature', description, price_eur_monthly, oneshot,
  is_active, is_visible, highlight, display_order, highlights, null, created_at, now()
from public.elocia_plans where key = 'pro'
on conflict (key) do nothing;

update public.elocia_plan_features set plan_key = 'signature' where plan_key = 'pro'
  and not exists (
    select 1 from public.elocia_plan_features f2
    where f2.plan_key = 'signature' and f2.feature_key = elocia_plan_features.feature_key
  );
delete from public.elocia_plan_features where plan_key = 'pro';

alter table public.elocia_profiles drop constraint if exists narro_profiles_subscription_tier_check;
update public.elocia_profiles set subscription_tier = 'signature' where subscription_tier = 'pro';
alter table public.elocia_profiles add constraint narro_profiles_subscription_tier_check
  check (subscription_tier = any (array['free'::text, 'solo'::text, 'signature'::text, 'team'::text, 'enterprise'::text]));

delete from public.elocia_plans where key = 'pro';

-- 3. Grille ---------------------------------------------------------------------
update public.elocia_plans set
  label = 'Solo',
  description = 'Du sujet au post planifié, Elocia accompagne chaque étape.',
  price_eur_monthly = 29, price_eur_yearly = 290, trial_days = 7,
  highlights = array[
    'Rédaction à partir d''un sujet, lien, fichier ou vocal',
    'Édition manuelle et planification',
    'Calendrier éditorial'
  ],
  highlight = false, is_visible = true, is_active = true, display_order = 10, updated_at = now()
where key = 'solo';

update public.elocia_plans set
  label = 'Signature',
  description = 'Trouvez les sujets qui comptent, affirmez votre point de vue et construisez votre voix.',
  price_eur_monthly = 59, price_eur_yearly = 590, trial_days = 7,
  highlights = array[
    'Rebond éditorial : sujets et angles issus de votre secteur, renouvelés chaque jour',
    'Temps forts de votre calendrier sectoriel',
    'Score de pertinence et recommandations avant publication',
    'Audit et maturité éditoriale',
    'Mémoire éditoriale : votre voix se construit dans le temps'
  ],
  highlight = true, is_visible = true, is_active = true, display_order = 20, updated_at = now()
where key = 'signature';

update public.elocia_plans set
  label = 'Équipe',
  description = 'Plusieurs comptes à piloter. Chaque voix conserve sa singularité.',
  price_eur_monthly = null, price_eur_yearly = null, stripe_price_id = null, stripe_price_id_yearly = null,
  trial_days = 0,
  highlights = array[
    'Tout Signature, pour chaque compte',
    'Gestion multi-comptes',
    'Calendrier et circuit de validation partagés',
    'Tableau de bord et reporting consolidés',
    'Onboarding accompagné (30 min), interlocuteur dédié, support chat prioritaire'
  ],
  highlight = false, is_visible = true, display_order = 30, updated_at = now()
where key = 'team';

update public.elocia_plans set is_visible = false, updated_at = now()
where key in ('free', 'enterprise', 'planif_post', 'audit_profil');

-- 4. Comptes gratuits existants : Signature en essai 7 jours -----------------------
update public.elocia_profiles set
  subscription_tier = 'signature',
  subscription_status = 'trialing',
  current_period_end = now() + interval '7 days',
  trial_started_at = now(),
  updated_at = now()
where subscription_tier = 'free'
  and stripe_subscription_id is null
  and role = 'client';
