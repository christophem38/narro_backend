-- Photo de profil réelle, uploadée par l'utilisateur.
--
-- Elocia pousse à l'incarnation (« Mon vécu », votre voix, vos preuves) et
-- l'aperçu du Générateur imite un post LinkedIn — où le visage EST la marque.
-- Jusqu'ici, seuls un personnage dessiné ou des initiales étaient possibles :
-- l'aperçu ne pouvait donc pas être fidèle. Cette colonne prend la priorité sur
-- l'avatar dessiné (cf. components/ElociaAvatar.tsx).
--
-- Le jour où l'API LinkedIn sera branchée, elle pourra remplir ce même champ.
alter table public.elocia_profiles
  add column if not exists avatar_url text;

-- Bucket dédié (même schéma que narro-post-images, migration 0022).
insert into storage.buckets (id, name, public)
values ('elocia-avatars', 'elocia-avatars', true)
on conflict (id) do nothing;

-- Lecture publique : l'URL est servie telle quelle dans l'app.
drop policy if exists "avatars public read" on storage.objects;
create policy "avatars public read"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'elocia-avatars');

-- Upload : utilisateur authentifié. Le chemin commence par son id de profil,
-- ce qui évite les collisions entre comptes.
drop policy if exists "avatars upload" on storage.objects;
create policy "avatars upload"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'elocia-avatars');

-- Remplacement d'une photo : on écrase le fichier précédent.
drop policy if exists "avatars update own" on storage.objects;
create policy "avatars update own"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'elocia-avatars' and owner = auth.uid());

drop policy if exists "avatars delete own" on storage.objects;
create policy "avatars delete own"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'elocia-avatars' and owner = auth.uid());
