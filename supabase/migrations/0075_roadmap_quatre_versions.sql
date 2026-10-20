-- 0075 : la roadmap décrit à nouveau le produit réel.
--
-- Le plan gratuit n'est plus vendu (la landing ne propose que Solo et
-- Signature, essai de 7 jours, carte à l'inscription) et le quota par offre a
-- laissé place à un plafond unique de 40 actions par jour. Les versions
-- parlaient donc d'un produit qui n'existe plus.
--
-- Quatre versions numérotées, dans l'ordre voulu par la super-admin :
--   V1 Ouverture commerciale              V2 Entreprise
--   V3 Améliorations avec retours users   V4 Améliorations continues
--
-- Les versions sont RENOMMÉES, pas recréées : chantiers, propositions en
-- attente et liens restent intacts. Elles sont retrouvées par leur ORDRE et
-- non par leur nom — la roadmap est éditée en direct dans l'interface, les
-- noms bougent, les positions beaucoup moins.
--
-- Données uniquement, aucune modification de schéma.

do $$
declare
  v1 uuid; v2 uuid; v3 uuid; v4 uuid;
begin
  -- Correspondance des versions actuelles vers les nouvelles :
  --   0 « Lancement… »       -> V1 Ouverture commerciale
  --   3 « Offre Entreprise »  -> V2 Entreprise
  --   1 « Finition… »         -> V3 Retours utilisateurs
  --   2 « Offre Pro… »        -> V4 Améliorations continues
  select id into v1 from public.elocia_roadmap_jalons where ordre = 0 limit 1;
  select id into v2 from public.elocia_roadmap_jalons where ordre = 3 limit 1;
  select id into v3 from public.elocia_roadmap_jalons where ordre = 1 limit 1;
  select id into v4 from public.elocia_roadmap_jalons where ordre = 2 limit 1;

  if v1 is null or v2 is null or v3 is null or v4 is null then
    raise exception 'Les quatre versions attendues (ordres 0 à 3) sont introuvables : rien n''a été modifié.';
  end if;

  -- 1) Fusions demandées par les propositions elles-mêmes ----------------
  -- Deux propositions acceptées disaient « recoupe un chantier existant :
  -- à fusionner ». La fusion n'a pas été faite, le doublon est resté.

  update public.elocia_roadmap_chantiers
     set commentaire = 'Bloque l''inscription : Supabase plafonne l''envoi, aucun email de confirmation n''arrive (constaté le 15/10, contourné par « déjà confirmé »).',
         updated_at = now()
   where item like 'Nom de domaine dédié%';
  delete from public.elocia_roadmap_chantiers where item like 'Emails transactionnels : bloquant%';

  update public.elocia_roadmap_chantiers
     set item = 'Rôles, statuts et circuit de relecture avant publication',
         commentaire = 'Brouillon, à relire, corrections demandées, validé, publié. Commentaires de relecture et historique. Scénario type : un stagiaire génère et améliore, d''autres relisent.',
         updated_at = now()
   where item like 'Rôles et circuit de validation%';
  delete from public.elocia_roadmap_chantiers where item like 'Circuit de relecture : le stagiaire%';

  -- 2) Chantiers périmés --------------------------------------------------
  -- Le quota par offre n'existe plus (lib/ai-quota.ts : plafond unique à 40).

  delete from public.elocia_roadmap_chantiers
   where item in ('Quota gratuit à 15 générations/jour', 'Quota Solo à 30 générations/jour');

  -- 3) Chantiers mal placés ----------------------------------------------

  -- Stripe conditionne l'ouverture : sans lui, rien ne se vend.
  update public.elocia_roadmap_chantiers set jalon_id = v1, horizon = 'court', updated_at = now()
   where item like 'Paiement Stripe%';

  -- Nés d'un point produit : ils appartiennent aux retours utilisateurs.
  update public.elocia_roadmap_chantiers set jalon_id = v3, horizon = 'court', updated_at = now()
   where item like 'Cadrage : questions à 4-5%'
      or item like 'Mettre en avant le nombre de caractères%'
      or item like 'Cliquer une version la recharge%'
      or item like 'Enrichissement du profil via le site%'
      or item like 'L''IA du hub profile l''utilisateur%';

  -- Dépendent d'un tiers ou se construisent sur des mois : aucune date ne
  -- tient, donc V4.
  update public.elocia_roadmap_chantiers set jalon_id = v4, horizon = 'long', updated_at = now()
   where item in ('Connexion LinkedIn', 'Publication directe sur LinkedIn', 'Modèle LoRA maison');

  -- 4) Ce qui manquait ----------------------------------------------------
  -- La page de prix promet déjà l'essai ; il n'était dans aucune version.

  if not exists (select 1 from public.elocia_roadmap_chantiers where item like 'Essai de 7 jours%') then
    insert into public.elocia_roadmap_chantiers (jalon_id, ordre, item, etat, source, commentaire, horizon)
    values (v1, 999, 'Essai de 7 jours sans engagement', 'a_faire', 'verifie_code',
            'Annoncé sur la page de prix (« essayer Solo ou Signature pendant 7 jours »), implémenté nulle part. Dépend de Stripe.',
            'court');
  end if;

  -- 5) Libellés, ordre, dates et horizons --------------------------------
  -- Dates : des cibles tenables au 20/10/2026, pas des engagements. Stripe
  -- n'est pas commencé, et c'est lui qui conditionne V1.

  update public.elocia_roadmap_jalons set
    ordre = 0, nom = 'V1',
    objectif = 'Ouverture commerciale — vendre Solo et Signature, avec une semaine d''essai',
    echeance = '2026-12-31', horizon = 'court', confiance = 'moyenne',
    avertissement = 'Tout dépend de Stripe, qui n''est pas commencé. Les trois chantiers déjà faits (ouverture publique, SEO/GEO, blocage de l''auto-upgrade) ne suffisent pas à encaisser.',
    actions = 'Appliquer les migrations 0070 à 0075 en production
Poser NEXT_PUBLIC_SITE_URL
Activer Vercel Web Analytics
Supprimer les 2 comptes de test d''audit',
    updated_at = now()
  where id = v1;

  update public.elocia_roadmap_jalons set
    ordre = 1, nom = 'V2',
    objectif = 'Entreprise — servir une équipe et son circuit de relecture, pas un individu',
    echeance = '2027-03-31', horizon = 'moyen', confiance = 'faible',
    avertissement = 'Cible devenue prioritaire au point du 14/10. Le contenu reste largement à spécifier : rôles, statuts d''un post, règles de publication.',
    actions = '', updated_at = now()
  where id = v2;

  update public.elocia_roadmap_jalons set
    ordre = 2, nom = 'V3',
    objectif = 'Améliorations avec retours utilisateurs — corriger ce que l''usage révèle',
    echeance = '2027-06-30', horizon = 'moyen', confiance = 'moyenne',
    avertissement = 'Alimentée par les points produit : les propositions issues des comptes rendus atterrissent ici par défaut.',
    actions = 'Points produit avec Aurélie : lundi et mercredi à 17h15
Verser chaque compte rendu dans la roadmap et dans le hub d''amélioration',
    updated_at = now()
  where id = v3;

  update public.elocia_roadmap_jalons set
    ordre = 3, nom = 'V4',
    objectif = 'Améliorations continues — ce qui se construit dans la durée',
    echeance = '', horizon = 'long', confiance = 'faible',
    avertissement = 'Sans échéance, volontairement : ce n''est pas un jalon mais un fil. On y range ce qui progresse sans date de fin.',
    actions = '', updated_at = now()
  where id = v4;

  -- 6) Renumérotation des chantiers au sein de chaque version -------------
  -- Les états d'abord : ce qui bloque et ce qui avance, avant ce qui est fait.
  with ordonne as (
    select c.id,
           row_number() over (
             partition by c.jalon_id
             order by case c.etat
                        when 'bloque_externe' then 0
                        when 'en_cours' then 1
                        when 'a_faire' then 2
                        else 3 end,
                      c.ordre, c.created_at) - 1 as rang
      from public.elocia_roadmap_chantiers c
  )
  update public.elocia_roadmap_chantiers c
     set ordre = o.rang
    from ordonne o
   where o.id = c.id and c.ordre is distinct from o.rang;

  update public.elocia_roadmap_meta
     set version = 'quatre versions · 20 octobre 2026', updated_at = now(), updated_by = 'Claude'
   where id = 1;
end $$;

notify pgrst, 'reload schema';
