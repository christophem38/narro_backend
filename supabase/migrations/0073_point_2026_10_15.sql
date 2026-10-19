-- 0073 : point du 15/10/2026 (Marion / Aurélie) et ses propositions.
--
-- Même principe que 0072 : le compte rendu est enregistré, les propositions en
-- sont tirées, et RIEN n'entre dans la roadmap sans un clic de la super-admin.
-- Elles arrivent donc en « pending ».
--
-- Crée au passage le jalon « Finition après retours d'usage », placé juste
-- après le lancement, pour accueillir ces retours sans surcharger un jalon déjà
-- daté. Additive et rejouable : ne s'exécute qu'une fois.

do $$
declare
  v_point     uuid;
  v_finition  uuid;
  v_gratuit   uuid;
  v_ordre     int;
begin
  if exists (select 1 from public.elocia_roadmap_points where titre = 'Point du 15/10/2026') then
    return;
  end if;

  select id into v_gratuit from public.elocia_roadmap_jalons
   where nom = 'Lancement du plan gratuit' limit 1;

  select id into v_finition from public.elocia_roadmap_jalons
   where nom = 'Finition après retours d''usage' limit 1;

  if v_finition is null then
    -- Inséré juste après le lancement ; les suivants décalent d'un cran.
    select ordre into v_ordre from public.elocia_roadmap_jalons
     where nom = 'Lancement du plan gratuit' limit 1;
    if v_ordre is null then
      select coalesce(max(ordre), -1) into v_ordre from public.elocia_roadmap_jalons;
    else
      update public.elocia_roadmap_jalons set ordre = ordre + 1 where ordre > v_ordre;
    end if;

    insert into public.elocia_roadmap_jalons
      (ordre, nom, echeance, objectif, confiance, avertissement, actions, horizon)
    values (
      v_ordre + 1,
      'Finition après retours d''usage',
      '2026-11-30',
      'Corriger ce que l''usage réel a révélé',
      'moyenne',
      'Issu du point produit du 15 octobre avec Aurélie. Sauf mention contraire, ces constats viennent de l''observation en séance et n''ont pas été vérifiés dans le code.',
      'Points produit avec Aurélie : lundi et mercredi à 17h15
Verser chaque compte rendu dans la roadmap et dans le hub d''amélioration',
      'court'
    )
    returning id into v_finition;
  end if;

  insert into public.elocia_roadmap_points (point_date, titre, contenu, created_by, processed_at)
  values ('2026-10-15', 'Point du 15/10/2026', 'Point produit Marion / Aurélie sur le staging, environ 55 min. Aurélie découvre l''app en conditions réelles.

1. Accès au staging : près d''une heure perdue sur Vercel (compte, 2FA, invitation, 404), puis second verrou, la base du staging est séparée. Aucun email de confirmation n''arrive (plafond Supabase), contourné par « déjà confirmé ».
2. Onboarding jugé trop long ; le récap semble cliquable sans l''être ; le nom « Elocia » revient trop souvent dans les libellés.
3. Décision : le générateur « coach » (parcours guidé) remplace le générateur initial. Le fond est validé, les réserves portent sur le détail.
4. Versions du post : pas d''historique conservé, cliquer une version ne recharge pas le texte, et tout doit rester sur un seul écran.
5. Hub d''amélioration : la sélection de texte est invisible ; annoncer les nouveautés dans l''app.
6. Profil : un profil incomplet ne se voit pas ; vérifier que les sujets à éviter sont respectés.
7. Décision : engager un redesign de la charte graphique (le vert de marque se confond avec le vert de la note).
8. Rituel : points lundi et mercredi à 17h15 à partir du 26/10.

Déjà traité depuis : ampoule accessible partout (18058fd), latence du parcours guidé (0677df1).

Compte rendu complet : docs/points/2026-10-15-point-elocia.md.', 'Claude (compte rendu du 15/10)', now())
  returning id into v_point;

  insert into public.elocia_roadmap_propositions
    (point_id, kind, titre, detail, horizon, jalon_id, extrait) values
  (v_point, 'chantier', 'Emails transactionnels : bloquant pour l''inscription',
   'Aucun email de confirmation n''arrive (plafond d''envoi Supabase), contourné par le bouton « déjà confirmé ». Recoupe le chantier existant « Nom de domaine dédié + emails transactionnels (Resend) » : à fusionner si accepté.',
   'court', v_gratuit, 'Il y a toujours eu un bug avec, là je ne reçois aucun email.'),
  (v_point, 'chantier', 'Le générateur « coach » remplace le générateur initial',
   'Décidé en séance : l''ancienne version du générateur disparaît au profit du parcours guidé.',
   'court', v_finition, 'Je vais virer cette version du générateur, je vais mettre celle sur laquelle j''ai travaillé directement en initial.'),
  (v_point, 'chantier', 'Conserver l''historique des versions en base',
   'Une modification écrase la précédente : l''historique est perdu. Les versions doivent persister.',
   'court', v_finition, 'Ça ne conserve pas le texte dans la base de données. Il faut bien qu''on garde les historiques des versions.'),
  (v_point, 'chantier', 'Cliquer une version la recharge dans le générateur',
   'Cliquer 1, 2, 3 ou 4 ne remet pas le texte correspondant.',
   'court', v_finition, 'Il faudrait que le texte qui est dans le générateur s''actualise automatiquement quand je clique sur 2.'),
  (v_point, 'chantier', 'Sélecteur de versions sous le post, sans faire défiler',
   'Naviguer entre les versions juste sous le post. Contrainte ferme : tout doit rester sur un seul écran.',
   'court', v_finition, 'Si tu reproposes encore quelque chose où il faut redescendre, les gens le feront pas.'),
  (v_point, 'chantier', 'Bloc « cadrage » dépliable sur place',
   'Y revenir renvoie aujourd''hui au générateur et fait perdre le fil du coach.',
   'court', v_finition, 'Tout le bloc cadrage, qu''on le retrouve en version déroulée quand on clique dessus.'),
  (v_point, 'chantier', 'Longueur « Long » ramenée de 1500 à environ 1200 caractères',
   '1500 caractères jugés trop longs à l''usage.',
   'court', v_finition, '1500 caractères, c''est long. Peut-être 1200.'),
  (v_point, 'chantier', 'Renommer « Améliorer » en « Mon coach »',
   'Mentionner le coach dans le libellé de l''outil.',
   'court', v_finition, 'Appeler le coach, quoi. Mentionner le coach.'),
  (v_point, 'chantier', 'Signaler une retouche qui fait baisser la note',
   'La renotation automatique après modification plaît, mais une baisse passe inaperçue.',
   'court', v_finition, 'La note, elle a baissé. Donc il faudrait que ça refuse si ça fait baisser la note.'),
  (v_point, 'chantier', 'Croix de fermeture sur le panneau du coach',
   'Il manque un moyen de fermer le panneau.',
   'court', v_finition, 'Il manque la petite croix.'),
  (v_point, 'chantier', 'Insérer les émojis à la position du curseur',
   'Ils atterrissent toujours en fin de texte, quel que soit l''endroit du curseur.',
   'court', v_finition, 'Peu importe où j''ai mis mon curseur, ça me le met toujours à la fin du texte.'),
  (v_point, 'chantier', 'Retirer les émojis du sélecteur de hashtags',
   'Le sélecteur de hashtags propose des émojis : hors sujet.',
   'court', v_finition, 'Dans les hashtags, pourquoi ça me sort les émojis ?'),
  (v_point, 'chantier', 'Ne plus suggérer « ajouter une image » en premier',
   'La suggestion arrive en tête alors qu''elle est rarement pertinente.',
   'court', v_finition, 'On a vu que c''est suggéré en premier, je pense qu''il ne faut pas qu''on le mette.'),
  (v_point, 'chantier', 'Revoir l''aperçu du post',
   'Cases accrochées, rendu peu soigné ; l''icône œil jugée inutile.',
   'court', v_finition, 'J''aime pas du tout les cases accrochées comme ça, c''est pas très beau.'),
  (v_point, 'chantier', 'Retirer « durée » et « comparer les versions »',
   'Ajoutés pendant une démo, sans usage réel.',
   'court', v_finition, 'Durée de 5 minutes 20, ça veut dire quoi ? Pour comparer, ça, on va enlever.'),
  (v_point, 'chantier', 'Personnaliser les idées suggérées',
   'Les trois idées proposées ne tiennent pas compte du profil rempli à l''onboarding.',
   'court', v_finition, 'C''est trop générique, ça n''a rien à voir avec mon expérience et mon onboarding.'),
  (v_point, 'chantier', 'Cesser de répéter « Elocia » dans les libellés',
   '« aider Elocia à comprendre mon ton », « style recommandé par Elocia » : uniformiser la formulation.',
   'court', v_finition, 'Je ne trouve pas ça fluide que le nom de la marque apparaisse à chaque fois.'),
  (v_point, 'chantier', 'Brider les textes descriptifs générés',
   'L''IA ajoute trop de petites descriptions qui surchargent les pages : en retirer plutôt qu''en ajouter.',
   'court', v_finition, 'L''IA, quand elle fait des trucs, elle met trop trop de textes. Ça parasite et ça surcharge la page.'),
  (v_point, 'chantier', 'Nettoyer les textes techniques visibles',
   '« dismiss », « page app easy post » et autres restes de code apparaissent à l''écran.',
   'court', v_finition, 'Il faudra qu''on revoie les textes, genre page app easy post, je ne sais pas ce que ça veut dire.'),
  (v_point, 'chantier', 'Rendre visible un profil incomplet',
   'Pourcentage ou couleur : aujourd''hui rien ne signale ce qui manque.',
   'court', v_finition, 'Mettre un niveau, quelque chose qui montre que c''est pas fait, parce que là, c''est pas clair.'),
  (v_point, 'chantier', 'Le hub d''amélioration questionne quand le profil est pauvre',
   'Si le profil n''est pas assez rempli, poser des questions pour le compléter au fil de l''usage.',
   'court', v_finition, 'Je vais le mettre aussi dans le hub d''amélioration : si le profil n''est pas assez rempli, poser des questions.'),
  (v_point, 'chantier', 'Vérifier que les sujets à éviter sont respectés',
   '« Pas de politique » doit exclure la politique des idées proposées. Annoncé comme acquis en séance, jamais vérifié dans le code.',
   'court', v_finition, 'Si la personne dit pas de politique, il faudrait que la politique ne soit pas suggérée.'),
  (v_point, 'chantier', 'Récap d''onboarding : lever l''ambiguïté du clic',
   'Les cartes du récapitulatif semblent cliquables alors qu''elles ne le sont pas.',
   'court', v_finition, 'T''as l''impression qu''on peut cliquer, en fait.'),
  (v_point, 'chantier', 'Clarifier « Membre » sur la fiche profil',
   'Le libellé n''est compris par personne.',
   'court', v_finition, 'Ça me met « membre », ça veut dire quoi ?'),
  (v_point, 'chantier', 'Expliquer « sélectionner du texte pour améliorer »',
   'La fonction est invisible : rien ne l''annonce, donc personne ne la découvre.',
   'court', v_finition, 'Il faut que la personne comprenne, parce que comment tu veux qu''on sache si c''est pas expliqué ?'),
  (v_point, 'chantier', 'Annoncer les nouveautés dans l''app',
   'Un mot au retour de l''utilisateur, façon journal des modifications, pour faire connaître les fonctions ajoutées.',
   'court', v_finition, 'Tu mets un peu au courant, comme une newsletter, l''utilisateur des nouvelles fonctionnalités.'),
  (v_point, 'chantier', 'Reprendre un onboarding interrompu',
   'En cas de bug ou de fermeture, ne pas repartir de zéro.',
   'court', v_finition, 'Comment ça se passe s''il y a un bug et que mon onboarding repart à zéro ?'),
  (v_point, 'chantier', 'Remplacer le formulaire d''onboarding par un parcours conversationnel',
   'Onboarding jugé trop long. Le prototype existe déjà (app/onboarding, mode=chat, aperçu super-admin). Décidé : après le lancement, pas avant.',
   'court', v_finition, 'Je trouve qu''il est long. Donc cette partie-là, il va falloir qu''on le change.'),
  (v_point, 'chantier', 'Redesign de la charte graphique',
   'Deux motifs distincts : le vert de marque se confond avec le vert « bonne note », donc l''évaluation ne ressort pas ; et le vert « fait bon élève ». Pistes évoquées : bleu, violet, rose. Chantier transverse — jetons Tailwind, slides, captures, documentation.',
   'moyen', v_finition, 'Le vert, je trouve ça fait un peu bon élève, et du coup ça ressort pas assez quand on donne une note.'),
  (v_point, 'arbitrage', 'Le jalon « Lancement du plan gratuit » décrit un produit qui n''existe plus',
   'Vérifié dans le code le 19/10 : la landing ne propose plus que Solo et Signature, avec un essai de 7 jours et carte à l''inscription ; le quota par offre a laissé place à un plafond unique de 40 actions par jour (lib/ai-quota.ts, commentaire « ancien gratuit (masqué) »). Les chantiers « Quota gratuit à 15 générations/jour » et « Quota Solo à 30 générations/jour » sont donc périmés. Renommer le jalon et retirer ces deux chantiers ?',
   'court', null, 'Moi, version gratuite, et j''aime bien aussi rester en version gratuite.'),
  (v_point, 'arbitrage', 'Comment ouvrir le staging aux relecteurs non techniques',
   'Aurélie a passé près d''une heure sur Vercel avant de voir l''app (compte, 2FA, invitation, 404). Trois options, toutes disponibles sur le plan Pro : sièges Viewer gratuits et illimités (recommandé, le staging reste fermé) ; exception de protection sur le domaine (accès sans compte, mais staging public — corriger robots.ts avant) ; lien partageable (par déploiement, à repartager à chaque push).',
   'court', null, 'Il faut vraiment que je puisse donner accès au staging aux autres super admins.');

end $$;

notify pgrst, 'reload schema';