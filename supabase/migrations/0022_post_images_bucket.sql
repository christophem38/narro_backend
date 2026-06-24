-- 0022_post_images_bucket.sql
-- Bucket Storage pour les images personnalisees uploadees par
-- les utilisateurs sur leurs inspirations / brouillons.
-- 2026-06-24

insert into storage.buckets (id, name, public)
values ('narro-post-images', 'narro-post-images', true)
on conflict (id) do nothing;

-- Lecture publique : les images sont servies directement depuis
-- le post LinkedIn, donc URL publique.
drop policy if exists "post images public read" on storage.objects;
create policy "post images public read"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'narro-post-images');

-- Upload : les utilisateurs authentifies peuvent uploader.
-- Le path commence par leur user id pour eviter les collisions.
drop policy if exists "post images upload" on storage.objects;
create policy "post images upload"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'narro-post-images');

-- Update / delete : owner only.
drop policy if exists "post images delete own" on storage.objects;
create policy "post images delete own"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'narro-post-images' and owner = auth.uid());
