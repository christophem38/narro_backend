-- 0037 : Resume d'article sur elocia_news_sources
--
-- CONTEXTE : le parser RSS (lib/feeds.ts) extrait deja un resume/extrait de
--   chaque article (champ FeedItem.summary), mais buildNewsRows le jetait :
--   seuls le titre et l'URL etaient persistes. Cote generation (Rebond
--   editorial, Inspiration), l'IA ne recevait donc que le TITRE d'un article —
--   insuffisant pour construire un angle solide.
--
-- APRES : chaque article garde son resume. Le Rebond l'injecte dans les prompts
--   de construction d'angle et de redaction, en plus du titre.
--
-- Colonne nullable : les articles ingeres avant cette migration n'ont pas de
--   resume, et la lecture cote app tolere l'absence (repli sur le titre seul).
--
-- Idempotent.

alter table public.elocia_news_sources
  add column if not exists summary text;

comment on column public.elocia_news_sources.summary is
  'Extrait/resume de l''article issu du flux RSS (description ou content). Injecte dans les prompts de generation en plus du titre.';
