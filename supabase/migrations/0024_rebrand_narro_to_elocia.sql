-- 0024 : rebrand Narro -> Elocia
--
-- Renomme les 29 tables narro_* en elocia_*. Postgres propage automatiquement :
--   - les cles primaires et etrangeres (les contraintes conservent leur nom
--     interne mais pointent bien vers la nouvelle table)
--   - les index (idem)
--   - les policies RLS (elles restent attachees a la nouvelle table)
--   - les triggers
--   - les vues et fonctions qui referencaient la table (Postgres met a jour
--     les dependances quand elles sont detectees via ALTER TABLE ... RENAME).
--
-- IMPORTANT : les vues/fonctions/triggers utilisant EXECUTE dynamique avec le
-- nom code en dur ne sont PAS mises a jour. Aucune trouvee dans le schema
-- actuel, donc pas d'action supplementaire. Les nouvelles migrations doivent
-- ecrire elocia_* directement.

ALTER TABLE IF EXISTS public.narro_ai_calls RENAME TO elocia_ai_calls;
ALTER TABLE IF EXISTS public.narro_brand_evidences RENAME TO elocia_brand_evidences;
ALTER TABLE IF EXISTS public.narro_brand_guardrails RENAME TO elocia_brand_guardrails;
ALTER TABLE IF EXISTS public.narro_brand_key_messages RENAME TO elocia_brand_key_messages;
ALTER TABLE IF EXISTS public.narro_brand_language_elements RENAME TO elocia_brand_language_elements;
ALTER TABLE IF EXISTS public.narro_brand_territories RENAME TO elocia_brand_territories;
ALTER TABLE IF EXISTS public.narro_brand_voice RENAME TO elocia_brand_voice;
ALTER TABLE IF EXISTS public.narro_editorial_strategy RENAME TO elocia_editorial_strategy;
ALTER TABLE IF EXISTS public.narro_events RENAME TO elocia_events;
ALTER TABLE IF EXISTS public.narro_features RENAME TO elocia_features;
ALTER TABLE IF EXISTS public.narro_holidays RENAME TO elocia_holidays;
ALTER TABLE IF EXISTS public.narro_hot_topics RENAME TO elocia_hot_topics;
ALTER TABLE IF EXISTS public.narro_keywords RENAME TO elocia_keywords;
ALTER TABLE IF EXISTS public.narro_marronniers RENAME TO elocia_marronniers;
ALTER TABLE IF EXISTS public.narro_network_influences RENAME TO elocia_network_influences;
ALTER TABLE IF EXISTS public.narro_news_feeds RENAME TO elocia_news_feeds;
ALTER TABLE IF EXISTS public.narro_news_sources RENAME TO elocia_news_sources;
ALTER TABLE IF EXISTS public.narro_plan_features RENAME TO elocia_plan_features;
ALTER TABLE IF EXISTS public.narro_plans RENAME TO elocia_plans;
ALTER TABLE IF EXISTS public.narro_profiles RENAME TO elocia_profiles;
ALTER TABLE IF EXISTS public.narro_progress_tasks RENAME TO elocia_progress_tasks;
ALTER TABLE IF EXISTS public.narro_published_posts RENAME TO elocia_published_posts;
ALTER TABLE IF EXISTS public.narro_suggested_posts RENAME TO elocia_suggested_posts;
ALTER TABLE IF EXISTS public.narro_super_admin_emails RENAME TO elocia_super_admin_emails;
ALTER TABLE IF EXISTS public.narro_teams RENAME TO elocia_teams;
ALTER TABLE IF EXISTS public.narro_tracked_influencers RENAME TO elocia_tracked_influencers;
ALTER TABLE IF EXISTS public.narro_used_angles RENAME TO elocia_used_angles;
ALTER TABLE IF EXISTS public.narro_user_feedback RENAME TO elocia_user_feedback;
ALTER TABLE IF EXISTS public.narro_weekly_digests RENAME TO elocia_weekly_digests;

-- Bucket Storage (narro-post-images) : on garde son nom pour ne pas casser les
-- URLs deja stockees dans elocia_published_posts.visual_url. Un rename creerait
-- un nouveau bucket vide et les images deja uploadees deviendraient 404.
-- Un rename de bucket sera fait dans une migration ulterieure une fois le
-- backfill decide.
