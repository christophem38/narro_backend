-- Amorce de sujets (offre gratuite) : cache des 3 idées du jour, qui sert aussi
-- de plafond quotidien (1 génération LLM/jour). Forme : { "day": "AAAA-MM-JJ",
-- "ideas": ["…","…","…"] }. Voir lib/actions.ts → brainstormTopics.
-- Tant que cette colonne n'existe pas, la génération marche mais sans plafond
-- (dégradation gracieuse).
alter table public.elocia_profiles
  add column if not exists topic_ideas jsonb;
