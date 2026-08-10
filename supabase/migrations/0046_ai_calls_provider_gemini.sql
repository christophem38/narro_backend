-- Élargit la contrainte CHECK sur elocia_ai_calls.provider pour accepter les
-- fournisseurs réellement utilisés par l'app mais absents de la liste d'origine
-- (migration 0008 : anthropic / perplexity / linkedin / openai).
--
-- Motivation : le garde-fou de quota IA (lib/ai-quota.ts) compte les lignes de
-- elocia_ai_calls sur 24 h glissantes. Les extractions Gemini (transcription
-- vocale, lecture d'URL, lecture de fichier) ne pouvaient pas y être journalisées
-- — 'gemini' violait le CHECK — donc elles échappaient au comptage. En les
-- autorisant, ces appels comptent dans le quota ET deviennent visibles dans le
-- tableau de bord de coûts admin.
--
-- Le nom de la contrainte inline générée par Postgres a été figé AVANT le
-- renommage narro_→elocia (migration 0024), qui ne renomme pas les contraintes :
-- elle s'appelle donc encore, selon l'historique, narro_ai_calls_provider_check.
-- On droppe les deux noms possibles (si présents) avant de recréer, pour rester
-- idempotent quel que soit l'état réel de la base.

alter table public.elocia_ai_calls
  drop constraint if exists narro_ai_calls_provider_check;
alter table public.elocia_ai_calls
  drop constraint if exists elocia_ai_calls_provider_check;

alter table public.elocia_ai_calls
  add constraint elocia_ai_calls_provider_check
  check (
    provider in (
      'anthropic',
      'perplexity',
      'linkedin',
      'openai',
      'gemini',
      'deepseek',
      'unsplash'
    )
  );
