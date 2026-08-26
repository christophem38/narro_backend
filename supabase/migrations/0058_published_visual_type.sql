-- Format du post publié (image, album, video, carousel, poll, chart, quote, none).
--
-- Le format ne vivait que sur les SUGGESTIONS (elocia_suggested_posts). Les
-- statistiques ne pouvaient donc rien en dire, alors que c'est la dimension la
-- plus actionnable : « vos graphiques font +30 % ». L'angle, lui, est le sujet
-- du post — unique à chaque publication, donc inexploitable pour repérer un
-- motif ou exiger de la variété.
alter table public.elocia_published_posts
  add column if not exists visual_type text;

-- Reprise de l'existant : les posts issus d'une suggestion connaissent leur
-- format via origin_suggested_id.
update public.elocia_published_posts p
set visual_type = s.visual_type
from public.elocia_suggested_posts s
where p.origin_suggested_id = s.id
  and p.visual_type is null
  and s.visual_type is not null;
