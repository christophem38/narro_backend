-- 0081 : V1 — UNE SEULE OFFRE, Solo à 5 € HT / mois (décision du 12/11/2026).
--
-- Affichage : Solo seule offre visible (Signature et Équipe masquées, pas
-- supprimées : elles reviendront). Pas d'annuel en V1.
--
-- PAIEMENT : l'ancien prix Stripe de Solo (29 €) ne doit JAMAIS être facturé
-- sous un affichage à 5 €. On vide donc stripe_price_id : le paiement refuse
-- proprement (« plan non connecté à Stripe ») tant qu'un prix Stripe à 5 € HT
-- n'est pas créé puis renseigné (voir la ligne commentée tout en bas).
--
-- Comptes : les comptes Signature / Équipe sans abonnement Stripe (essais « maison »
-- de 0067, démos) passent sur Solo, en conservant leur essai. Un abonnement Stripe
-- réel n'est jamais touché.
--
-- Accès OFFERT (consultants TF, amis) : le super-admin met le compte sur Solo sans
-- abonnement Stripe (sélecteur d'offre) ; l'accès n'expire pas.
--
-- Idempotente.

update public.elocia_plans set
  label = 'Solo',
  description = 'Du sujet au post planifié, Elocia accompagne chaque étape.',
  price_eur_monthly = 5,
  price_eur_yearly = null,
  stripe_price_id = null,
  stripe_price_id_yearly = null,
  trial_days = 7,
  highlights = array[
    'Rédaction à partir d''un sujet, d''un lien, d''un fichier ou d''un vocal',
    'Votre voix, vos objectifs et vos audiences guident chaque post',
    'Coach : note, retouches et vérification des affirmations',
    'Édition manuelle, visuels et planification',
    'Calendrier éditorial et suivi de vos performances'
  ],
  highlight = true, is_visible = true, is_active = true, display_order = 10,
  updated_at = now()
where key = 'solo';

update public.elocia_plans set is_visible = false, updated_at = now()
where key in ('signature', 'team', 'enterprise', 'free', 'planif_post', 'audit_profil');

update public.elocia_profiles set
  subscription_tier = 'solo',
  updated_at = now()
where subscription_tier in ('signature', 'team', 'enterprise')
  and stripe_subscription_id is null
  and role = 'client';

-- À EXÉCUTER quand le prix Stripe « Solo 5 € HT / mois » est créé (remplacer l'identifiant) :
-- update public.elocia_plans set stripe_price_id = 'price_XXXXXXXX' where key = 'solo';
