-- 0054 : retours explicites sur les suggestions Inspiration
--
-- CONTEXTE : une carte Inspiration n'avait qu'une seule action, « Rediger ».
--   Aucun moyen de dire « pas pour moi ». L'IA ne savait donc RIEN de ce que
--   la personne rejette, et repropose semaine apres semaine des sujets, des
--   postures ou des angles dont elle ne veut pas. Pour un produit dont la
--   valeur tient a la pertinence des 5 propositions hebdomadaires, c'est le
--   manque le plus couteux.
--
-- APRES : trois motifs de refus, en un clic. Le refus masque la carte et
--   alimente le prompt de la generation suivante (« ce que la personne a
--   refuse, et pourquoi »).
--
-- Les motifs sont volontairement peu nombreux et orthogonaux : chacun agit
-- sur un levier different du prompt.
--   'sujet' -> le theme ne l'interesse pas          -> eviter ce theme
--   'ton'   -> le sujet va, pas la maniere de dire  -> changer de posture
--   'banal' -> deja vu, trop convenu                -> exiger un angle non evident
--
-- On stocke un INSTANTANE du titre et du theme : la ligne suggeree, elle, sera
-- supprimee au bout de trois semaines par la rotation (cf. commit « archiver
-- les semaines »). Le retour, lui, doit survivre pour rester exploitable.
--
-- Idempotent.

create table if not exists public.elocia_suggestion_feedback (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.elocia_profiles(id) on delete cascade,
  -- Pas de cle etrangere : la suggestion peut disparaitre, le retour reste.
  suggested_post_id text,
  reason text not null check (reason in ('sujet', 'ton', 'banal')),
  title text,
  theme text,
  created_at timestamptz not null default now()
);

create index if not exists elocia_suggestion_feedback_profile_idx
  on public.elocia_suggestion_feedback (profile_id, created_at desc);

alter table public.elocia_suggestion_feedback enable row level security;

drop policy if exists self_read on public.elocia_suggestion_feedback;
create policy self_read on public.elocia_suggestion_feedback
  for select to authenticated
  using (profile_id = auth.uid());

drop policy if exists self_write on public.elocia_suggestion_feedback;
create policy self_write on public.elocia_suggestion_feedback
  for insert to authenticated
  with check (profile_id = auth.uid());

drop policy if exists self_delete on public.elocia_suggestion_feedback;
create policy self_delete on public.elocia_suggestion_feedback
  for delete to authenticated
  using (profile_id = auth.uid());

-- Masquage de la carte refusee. Colonne plutot qu'un nouveau statut : le
-- statut porte le cycle de publication (draft -> approved -> scheduled ->
-- published), un refus n'en fait pas partie. Nullable = jamais refusee.
alter table public.elocia_suggested_posts
  add column if not exists dismissed_at timestamptz;

comment on column public.elocia_suggested_posts.dismissed_at is
  'Date du « pas pour moi ». Masque la carte dans Inspiration ; la ligne reste en base et dans Mes posts. Le motif est dans elocia_suggestion_feedback.';
