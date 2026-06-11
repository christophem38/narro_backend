-- Seed for the demo profile, mirroring narro.v0.3.html mock data.
do $$
declare
  demo_id uuid := '00000000-0000-0000-0000-000000000001';
begin
  insert into public.narro_profiles (id, display_name, role_label, linkedin_connected, weekly_target, style_instructions, editorial_user_tag)
  values (
    demo_id,
    'Votre Profil', 'Directeur', true, 2,
    'Je fais toujours des phrases directes et courtes. Je commence par une accroche percutante. Je conclus avec un call to action pour inciter les autres décideurs à partager leur retour d''expérience.',
    '@MarcSimon'
  )
  on conflict (id) do update
    set display_name = excluded.display_name,
        role_label = excluded.role_label,
        weekly_target = excluded.weekly_target,
        style_instructions = excluded.style_instructions,
        editorial_user_tag = excluded.editorial_user_tag,
        updated_at = now();

  delete from public.narro_keywords where profile_id = demo_id;
  delete from public.narro_tracked_influencers where profile_id = demo_id;
  delete from public.narro_suggested_posts where profile_id = demo_id;
  delete from public.narro_news_sources where profile_id = demo_id;
  delete from public.narro_network_influences where profile_id = demo_id;
  delete from public.narro_published_posts where profile_id = demo_id;
  delete from public.narro_events where profile_id = demo_id;

  insert into public.narro_keywords (profile_id, label) values
    (demo_id, 'Intelligence Artificielle'),
    (demo_id, 'SaaS B2B');

  insert into public.narro_tracked_influencers (profile_id, handle, tag, profile_url) values
    (demo_id, '@MarcSimon', 'Expert RH', 'https://linkedin.com');

  insert into public.narro_suggested_posts (id, profile_id, week_offset, type, category, date_label, text, visual_type, title, posture, angle, status, ordinal) values
    ('weekly-1', demo_id, 0, 'actu', 'Basé sur l''actualité', 'Mardi 10h00',
     E'L''annonce récente de la Commission Européenne sur la régulation de l''IA rebat les cartes pour notre secteur. 🇪🇺\n\nBeaucoup y voient un frein. Chez nous, j''y vois au contraire une opportunité de l''utiliser comme standard de confiance et d''éthique.\n\nL''innovation sans cadre n''est que chaos. C''est le moment pour les acteurs européens de montrer l''exemple.\n\n#IA #Tech #Europe #Régulation',
     'image', 'Régulation de l''IA - Actualité', 'Analyse marché', 'Opportunité de confiance', 'draft', 0),

    ('weekly-2', demo_id, 0, 'reseau', 'Rebond sur votre réseau', 'Suggestion chaude',
     E'Je lisais ce matin un excellent post sur les difficultés de recrutement des profils tech seniors en 2026. Le constat est juste.\n\nLe salaire ne suffit plus. Ce que nous remarquons chez nous, c''est que la flexibilité asynchrone est devenue le critère n°1, loin devant les avantages matériels.\n\nEt vous, dirigeants, quel est votre principal levier d''attractivité aujourd''hui ? 👇\n\n#Recrutement #Management #FutureOfWork',
     'carousel', 'Le paradoxe du recrutement Tech senior', 'Opinion personnelle', 'Focus flexibilité asynchrone', 'draft', 1),

    ('weekly-old-1', demo_id, -1, 'actu', 'Basé sur l''actualité', 'Publié le 02 Juin',
     E'La baisse globale des levées de fonds dans la tech au Q1 2026 n''est pas une crise, c''est un retour sain à la réalité économique. 📉\n\nFinie la course aux valorisations folles basées sur de simples fichiers Excel. Place aux critères fondamentaux : rentabilité, intégration produit et vrai "churn" maîtrisé.\n\nC''est la meilleure période pour construire de la valeur robuste.\n\n#Economie #Tech #SaaS #Raison',
     'chart', 'L''économie réelle rattrape la Tech', 'Analyse marché', 'Retour à la raison économique', 'published', 0),

    ('weekly-old-2', demo_id, -1, 'reseau', 'Rebond sur votre réseau', 'Manqué le 04 Juin',
     E'Pourquoi tant de fondateurs SaaS refusent encore de recruter des managers intermédiaires ?\n\nOn appelle ça le "syndrome du micro-management". C''est le moyen le plus rapide de fatiguer vos profils A-player et de bloquer votre croissance.\n\nLa confiance n''exclut pas le contrôle, mais le contrôle permanent détruit l''autonomie.\n\n#Management #RH #SaaS #Confiance',
     'quote', 'Le piège du micro-management', 'Conseil pratique', 'Micro-management vs Délégation', 'expired', 1),

    ('weekly-old-3', demo_id, -2, 'actu', 'Visite Salon', 'Publié le 25 Mai',
     E'De retour du salon Vivatech à Paris ! Une effervescence technologique indéniable, mais ma principale impression reste mitigée.\n\nOn frôle parfois l''excès de "gadgets IA" sans réel intérêt industriel. La différence entre un outil sympa et une solution business est pourtant abyssale.\n\nRecentrons l''IA sur la création de temps libre utile.\n\n#Vivatech #Paris #Tech #Utilité',
     'image', 'Vivatech : Du gadget à la vraie utilité', 'Retour d''expérience', 'Analyse à chaud post-salon', 'published', 0),

    ('weekly-old-4', demo_id, -2, 'reseau', 'Rebond réseau', 'Publié le 28 Mai',
     E'En B2B, l''erreur classique est de passer 90% du pitch à expliquer COMMENT fonctionne votre produit.\n\nVos clients s''en moquent. Ce qu''ils veulent savoir, c''est ce qu''ils vont GAGNER à vous utiliser : du temps libéré, des risques évités ou des coûts optimisés.\n\nVendez le résultat, pas la mécanique.\n\n#Sales #B2B #SaaS #Mindset',
     'quote', 'Vendez des résultats, pas des fonctionnalités', 'Conseil pratique', 'Focus valeur ajoutée', 'published', 1);

  insert into public.narro_news_sources (id, profile_id, week_offset, category, title, origin, logo, url, ordinal) values
    ('news-1', demo_id, 0, 'Tech', 'L''Europe vote la nouvelle loi sur la régulation de l''IA (AI Act).', 'TechCrunch', '⚡', 'https://techcrunch.com', 0),
    ('news-2', demo_id, 0, 'Économie', 'Baisse des levées de fonds dans la tech de 30% au Q1 2026.', 'Les Echos', '📈', 'https://lesechos.fr', 1),
    ('news-3', demo_id, 0, 'SaaS B2B', 'L''intégration native, nouvel eldorado pour contrer le "churn".', 'SaaS Club', '🔌', 'https://saasclub.com', 2),
    ('news-4', demo_id, 0, 'IA Globale', 'Les modèles locaux légers prennent le pas sur les gros serveurs cloud.', 'Silicon.fr', '🧠', 'https://silicon.fr', 3),
    ('news-old-1', demo_id, -1, 'Régulation', 'Le RGPD 2.0 en cours de discussion pour intégrer les agents d''IA autonomes.', 'L''Usine Digitale', '🛡️', 'https://usinedigitale.fr', 0),
    ('news-old-2', demo_id, -1, 'Productivité', 'La semaine de 4 jours séduit de plus en plus de grands groupes d''ingénierie.', 'Le Monde', '⏰', 'https://lemonde.fr', 1),
    ('news-old-3', demo_id, -1, 'Semiconducteurs', 'NVIDIA annonce sa nouvelle puce ultra-efficace pour les serveurs locaux.', 'Wired', '💾', 'https://wired.com', 2),
    ('news-old-4', demo_id, -2, 'Startup', 'Vivatech annonce un record d''affluence pour son édition 2026 à Paris.', 'La Tribune', '🗼', 'https://latribune.fr', 0),
    ('news-old-5', demo_id, -2, 'Management', 'Pourquoi le ''quiet quitting'' est remplacé par le ''quiet hiring'' cette année.', 'HBR France', '💼', 'https://hbrfrance.fr', 1);

  insert into public.narro_network_influences (id, profile_id, week_offset, user_handle, tag, text, logo, url, ordinal) values
    ('influence-1', demo_id, 0, '@MarcSimon', 'Expert RH', 'Le management hybride est mort, place à l''asynchrone total pour 2027.', 'MS', 'https://linkedin.com', 0),
    ('influence-2', demo_id, 0, '@JulieDupont', 'SaaS Strategy', 'Arrêtez de vendre des features. En B2B, on vend du temps libre.', 'JD', 'https://linkedin.com', 1),
    ('influence-3', demo_id, 0, '@PierreG', 'SaaS Founder', 'Le service client n''est pas un centre de coût, c''est votre principale source de R&D.', 'PG', 'https://linkedin.com', 2),
    ('influence-old-1', demo_id, -1, '@AntoineHR', 'Talent Acquisition', 'Si vos recruteurs passent encore 3h par jour à trier des CV, vous avez déjà perdu.', 'AH', 'https://linkedin.com', 0),
    ('influence-old-2', demo_id, -1, '@ClarisseData', 'CDO Specialist', 'Pas de bonne IA sans bonnes données. Nettoyez vos bases CRM avant de rêver de prédictions.', 'CD', 'https://linkedin.com', 1),
    ('influence-old-3', demo_id, -2, '@SarahInnov', 'Product Lead', 'La meilleure fonctionnalité produit est celle que vous supprimez parce qu''elle complexifie l''usage.', 'SI', 'https://linkedin.com', 0);

  insert into public.narro_published_posts (profile_id, title, content, posture, angle, status, published_at) values
    (demo_id, 'Régulation de l''IA Act en Europe', '', 'Analyse marché', 'Opportunité de confiance', 'Publié', '2026-06-08'::timestamptz),
    (demo_id, 'Le paradoxe du salaire et de la flexibilité', '', 'Opinion personnelle', 'Flexibilité asynchrone', 'Publié', '2026-06-04'::timestamptz);

  insert into public.narro_events (profile_id, title, description, suggested_text, event_date, event_type, status) values
    (demo_id,
     'Le futur de l''asynchrone en SaaS B2B',
     'Vous intervenez avec 2 autres experts. L''IA recommande 3 posts pour maximiser l''audience.',
     'Rendez-vous le 18 Juin prochain pour notre live exclusif sur le futur du SaaS B2B asynchrone ! Nous ferons sauter tous les mythes de l''organisation rigide. #Webinaire #SaaS #SaaSMetrics',
     '2026-06-18', 'webinar', 'upcoming'),
    (demo_id,
     'Vivatech 2026 - Paris',
     'L''événement est terminé. Profitez-en pour partager vos impressions à chaud.',
     'Vivatech 2026 c''est fini ! Une édition intense riche en échanges et en technologies disruptives. Mon principal constat ? L''IA se démocratise enfin et passe du gadget à l''industrie utile. #Vivatech #Paris #Innovation',
     '2026-05-22', 'salon', 'done');
end$$;
