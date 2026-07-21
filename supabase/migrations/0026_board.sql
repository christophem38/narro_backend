-- 0026 : table du board de retours utilisateur
--
-- Un unique document texte partage (id='main') + un drapeau d'etat
-- (id='status') pour piloter le cycle de traitement automatique.
-- Cf. /app/api/board/route.ts et .claude/skills/board-retours/SKILL.md.
--
-- RLS active : aucun acces direct depuis le navigateur. Seule la
-- service_role key (utilisee cote serveur par /api/board) peut lire /
-- ecrire - le controle d'acces se fait donc uniquement via l'obscurite
-- de l'URL /board, ce qui est le comportement voulu (page publique
-- sans authentification, l'URL fait office de secret).
--
-- Le bucket Storage `board-uploads` (pour les captures et documents
-- joints) est cree automatiquement au premier envoi par
-- /api/board/upload : rien a provisionner ici.

CREATE TABLE IF NOT EXISTS public.board (
  id         text PRIMARY KEY,
  content    text NOT NULL DEFAULT '',
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.board ENABLE ROW LEVEL SECURITY;
