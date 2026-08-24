-- Comparatif d'offres : dire la valeur, pas la liste des clés techniques.
--
-- CONSTAT : les cartes d'offres listaient les libellés des fonctionnalités
-- (« Accès à la page Inspiration », « Voir la page »…). Ça décrit un droit
-- d'accès, pas ce qu'on achète. Personne ne paie 19 € pour « voir une page ».
--
-- On ajoute donc 3 bénéfices en clair par offre, éditables depuis le
-- Super Admin — la copie commerciale doit pouvoir changer sans redéploiement.
--
-- Le détail technique n'est pas perdu : il reste consultable, replié.

alter table public.elocia_plans
  add column if not exists highlights text[] not null default '{}';

comment on column public.elocia_plans.highlights is
  'Bénéfices en langage client, affichés sur la carte d''offre. 3 lignes max — au-delà, plus personne ne lit.';

-- Amorce. À reformuler librement depuis Super Admin › Offres : ces phrases
-- décrivent ce que l'offre PERMET, jamais les pages qu'elle ouvre.
update public.elocia_plans set highlights = array[
  'Rédigez vos posts avec l''IA, sans partir d''une page blanche',
  'Planifiez vos publications et suivez vos résultats',
  '30 générations par jour'
] where key = 'free';

update public.elocia_plans set highlights = array[
  '5 prises de parole prêtes à écrire, chaque semaine',
  'Votre veille transformée en sujets : vos sources, l''actu de votre secteur',
  'Rebondissez sur l''actualité et les temps forts de votre agenda'
] where key = 'solo';

update public.elocia_plans set highlights = array[
  'Tout Solo, plus la relecture à plusieurs',
  'Un collègue valide vos posts avant publication',
  'Pour les entreprises où plusieurs voix s''expriment'
] where key = 'pro';

update public.elocia_plans set highlights = array[
  'Toutes les fonctionnalités, sans restriction',
  'Plusieurs collaborateurs, une seule ligne éditoriale',
  'Suivi de la prise de parole à l''échelle de l''équipe'
] where key = 'team';

update public.elocia_plans set highlights = array[
  'Accompagnement et support dédiés',
  'Adapté à vos contraintes et à votre volume',
  'Tarification sur mesure'
] where key = 'enterprise';

update public.elocia_plans set highlights = array[
  'Programmez vos prises de parole à l''avance',
  'Un calendrier éditorial et des rappels le jour J',
  'Sans la veille ni les suggestions hebdomadaires'
] where key = 'planif_post';

update public.elocia_plans set highlights = array[
  'Diagnostic complet de votre profil LinkedIn',
  'Vos points forts et ce qui vous freine, par écrit',
  'Paiement unique, sans abonnement'
] where key = 'audit_profil';
