-- 0053 : index de fraicheur sur la veille
--
-- CONTEXTE : la generation hebdo (5 suggestions Inspiration) et le digest
--   prenaient leurs signaux avec `.order("ordinal").limit(12)`. Or `ordinal`
--   est la POSITION DE L'ARTICLE DANS SON PROPRE FLUX (lib/feeds.ts) : avec
--   15 flux actifs il existe 15 lignes d'ordinal 0, 15 d'ordinal 1, etc. Le
--   tri ne departageait donc rien, et AUCUN filtre de date n'existait. Comme
--   elocia_news_sources n'etait jamais purgee, l'IA pouvait recevoir des
--   articles vieux de plusieurs mois pour rediger « l'actu de la semaine ».
--
-- APRES : l'app tire un vivier des lignes les plus recemment ingerees
--   (`order by created_at desc limit 120`) puis selectionne par date
--   effective (published_at, sinon created_at) sur une fenetre de 10 jours
--   (lib/news-window.ts). Le cron refresh-feeds purge au-dela de 30 jours.
--
-- Ces deux index servent exactement ces deux acces :
--   - (profile_id, week_offset, created_at desc) pour le vivier par profil
--   - (created_at) pour la purge globale du cron
--
-- Aucune donnee modifiee. Idempotent.

create index if not exists elocia_news_sources_profile_week_created_idx
  on public.elocia_news_sources (profile_id, week_offset, created_at desc);

create index if not exists elocia_news_sources_created_idx
  on public.elocia_news_sources (created_at);

create index if not exists elocia_network_influences_profile_week_created_idx
  on public.elocia_network_influences (profile_id, week_offset, created_at desc);

create index if not exists elocia_network_influences_created_idx
  on public.elocia_network_influences (created_at);
