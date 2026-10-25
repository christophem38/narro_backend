-- 0076 : la roadmap remise d'équerre sur le code réel (25/10/2026).
--
-- Constat : la roadmap décrivait un produit d'il y a trois mois. Elle
-- annonçait « Paiement Stripe : rien n'existe dans le repo » alors que
-- l'intégration date du 3 septembre. Cette phrase venait d'un plan écrit en
-- juillet, recopiée de version en version sans jamais être revérifiée.
--
-- Chaque état posé ici s'appuie sur une preuve dans le dépôt — commit, fichier
-- ou colonne — et cette preuve est écrite dans le commentaire du chantier.
-- C'est le seul moyen de ne pas recommencer : un chantier dont personne ne
-- peut dire d'où vient l'état dérive en quelques semaines.
--
-- Données uniquement. Les chantiers sont retrouvés par leur intitulé ; ceux
-- qui ont été renommés entre-temps ne sont simplement pas touchés.

do $$
declare v1 uuid;
begin
  select id into v1 from public.elocia_roadmap_jalons where nom = 'V1' limit 1;

  -- ===================================================================
  -- V1 — tout était déjà fait. Ce qui reste n'est pas du code.
  -- ===================================================================

  update public.elocia_roadmap_chantiers set
    etat = 'fait', source = 'verifie_code',
    commentaire = 'Intégré le 03/09/2026 (commit 98a9c71) : app/api/stripe/checkout, /portal, /webhook et lib/stripe.ts. Le webhook traite checkout.session.completed, les créations/mises à jour/suppressions d''abonnement et les échecs de paiement.',
    updated_at = now()
  where item like 'Paiement Stripe%';

  update public.elocia_roadmap_chantiers set
    etat = 'fait', source = 'verifie_code',
    commentaire = 'trial_period_days posé dans app/api/stripe/checkout/route.ts, et une seule fois par compte (trial_started_at).',
    updated_at = now()
  where item like 'Essai de 7 jours%';

  -- Le chantier mélangeait deux choses, dont une fausse : le transport n'est
  -- pas Resend mais nodemailer/SMTP OVH, et il fonctionne.
  update public.elocia_roadmap_chantiers set
    item = 'Nom de domaine et emails de l''application',
    etat = 'fait', source = 'verifie_code',
    commentaire = 'www.elopreview.biz répond, et lib/mailer.ts envoie via nodemailer (SMTP OVH) — pas Resend, contrairement à l''intitulé d''origine.',
    updated_at = now()
  where item like 'Nom de domaine dédié%';

  -- Le vrai blocage constaté le 15/10 n'était pas là : ce sont les emails de
  -- Supabase Auth, que l'application n'envoie pas elle-même.
  if v1 is not null
     and not exists (select 1 from public.elocia_roadmap_chantiers where item like 'Emails de confirmation d''inscription%') then
    insert into public.elocia_roadmap_chantiers (jalon_id, ordre, item, etat, source, commentaire, horizon)
    values (v1, 0, 'Emails de confirmation d''inscription (Supabase Auth)', 'a_faire', 'verifie_chat',
            'Aucun email n''arrive : Supabase plafonne fortement l''envoi en configuration par défaut. Constaté en direct le 15/10, contourné par le bouton « déjà confirmé ». À régler dans Authentication → Emails en y branchant un SMTP. Distinct des emails de l''application, qui fonctionnent.',
            'court');
  end if;

  update public.elocia_roadmap_jalons set
    avertissement = 'Le code est prêt : Stripe, essai de 7 jours, domaine et emails applicatifs sont en place depuis septembre. Ce qui reste est de la mise en service — déployer, poser les clés Stripe en mode live, brancher un SMTP sur Supabase Auth.',
    actions = 'Fusionner la PR #3 (le code de production date du 8 octobre)
Vérifier que les clés Stripe de production sont en mode live, et le webhook enregistré côté Stripe
Brancher un SMTP sur Supabase Auth (Authentication → Emails)
Poser NEXT_PUBLIC_SITE_URL sur l''environnement Production
Supprimer les 2 comptes de test d''audit',
    confiance = 'haute',
    updated_at = now()
  where id = v1;

  -- ===================================================================
  -- V3 — plusieurs retours du 15/10 sont partis depuis.
  -- ===================================================================

  update public.elocia_roadmap_chantiers set
    etat = 'fait', source = 'verifie_code',
    commentaire = 'Commit bced956 : le coach (parcours guidé) remplace l''ancien hub, pour tout le monde.',
    updated_at = now()
  where item like 'Le générateur « coach » remplace%';

  update public.elocia_roadmap_chantiers set
    etat = 'fait', source = 'verifie_code',
    commentaire = 'Commits 71bf333 puis ae94dfa : les réglages du cadrage se déroulent par-dessus le post, sans modale et sans perdre le fil.',
    updated_at = now()
  where item like 'Bloc « cadrage » dépliable%';

  update public.elocia_roadmap_chantiers set
    etat = 'fait', source = 'verifie_code',
    commentaire = 'Commit 1521158 : le post généré s''affiche en fenêtre plein écran, fermable par une croix.',
    updated_at = now()
  where item like 'Croix de fermeture%';

  update public.elocia_roadmap_chantiers set
    etat = 'fait', source = 'verifie_code',
    commentaire = 'Commits 1f78cf6 et a58365a, composant _flux/ProfilingCard.tsx : une question de profil par post, quand une information manque.',
    updated_at = now()
  where item like 'L''IA du hub profile l''utilisateur%';

  -- La persistance existait déjà ; c'est l'interface autour qui manque.
  update public.elocia_roadmap_chantiers set
    item = 'Historique des versions : persistance',
    etat = 'fait', source = 'verifie_code',
    commentaire = 'Colonne elocia_suggested_posts.versions (migration 0034), présente en staging ET en production ; écriture dans lib/actions.ts. Le reproche du 15/10 portait sur l''interface — recharger une version, la choisir sous le post — pas sur la conservation.',
    updated_at = now()
  where item like 'Conserver l''historique des versions%';

  update public.elocia_roadmap_chantiers set
    etat = 'en_cours', source = 'verifie_code',
    commentaire = 'Pull request #9 ouverte, pas encore fusionnée : rien dans le générateur ne l''affiche aujourd''hui.',
    updated_at = now()
  where item like 'Mettre en avant le nombre de caractères%';

  update public.elocia_roadmap_chantiers set
    source = 'verifie_code',
    commentaire = 'company_website est collecté à l''onboarding et stocké, mais rien ne va lire le site : aucun enrichissement n''existe.',
    updated_at = now()
  where item like 'Enrichissement du profil via le site%';

  -- ===================================================================
  -- V4 — revérifié, toujours pas fait.
  -- ===================================================================

  update public.elocia_roadmap_chantiers set
    source = 'verifie_code',
    commentaire = 'Revérifié le 25/10 : generateWeeklySuggestions ne reçoit toujours aucune métrique d''engagement. Les performances publiées n''influencent pas le classement des idées.',
    updated_at = now()
  where item like 'Boucle d''apprentissage%';

  -- ===================================================================
  update public.elocia_roadmap_meta
     set version = 'vérifiée contre le code · 25 octobre 2026', updated_at = now(), updated_by = 'Claude'
   where id = 1;
end $$;

notify pgrst, 'reload schema';
