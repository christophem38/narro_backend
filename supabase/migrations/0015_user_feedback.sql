-- 0015_user_feedback.sql
-- Widget feedback contextuel : remontées utilisateur avec screenshot,
-- contexte de page, fichier joint et statut pilotable.
-- 2026-06-15

create table if not exists public.narro_user_feedback (
  id              uuid primary key default gen_random_uuid(),
  profile_id      uuid not null references public.narro_profiles(id) on delete cascade,
  page_path       text not null,
  page_title      text,
  user_agent      text,
  viewport        text,
  message         text not null,
  screenshot_path text,
  attachment_path text,
  attachment_name text,
  attachment_type text,
  status          text not null default 'open'
    check (status in ('open', 'in_progress', 'resolved', 'wontfix')),
  admin_note      text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists narro_user_feedback_profile_idx
  on public.narro_user_feedback (profile_id, created_at desc);

create index if not exists narro_user_feedback_status_idx
  on public.narro_user_feedback (status, created_at desc);

alter table public.narro_user_feedback enable row level security;

drop policy if exists "feedback user insert own" on public.narro_user_feedback;
create policy "feedback user insert own"
  on public.narro_user_feedback
  for insert
  to authenticated
  with check (profile_id = auth.uid());

drop policy if exists "feedback select own or admin" on public.narro_user_feedback;
create policy "feedback select own or admin"
  on public.narro_user_feedback
  for select
  to authenticated
  using (
    profile_id = auth.uid()
    or public.narro_current_role() in ('admin', 'super_admin')
  );

drop policy if exists "feedback admin update" on public.narro_user_feedback;
create policy "feedback admin update"
  on public.narro_user_feedback
  for update
  to authenticated
  using (public.narro_current_role() in ('admin', 'super_admin'))
  with check (public.narro_current_role() in ('admin', 'super_admin'));

drop policy if exists "feedback admin delete" on public.narro_user_feedback;
create policy "feedback admin delete"
  on public.narro_user_feedback
  for delete
  to authenticated
  using (public.narro_current_role() in ('admin', 'super_admin'));

-- Bucket privé pour screenshots + fichiers joints (5 Mo max)
insert into storage.buckets (id, name, public, file_size_limit)
values ('narro-feedback', 'narro-feedback', false, 5242880)
on conflict (id) do update set file_size_limit = excluded.file_size_limit;

-- Storage RLS : un utilisateur ne peut écrire que dans son propre préfixe
drop policy if exists "feedback storage user insert" on storage.objects;
create policy "feedback storage user insert"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'narro-feedback'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "feedback storage user read" on storage.objects;
create policy "feedback storage user read"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'narro-feedback'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.narro_current_role() in ('admin', 'super_admin')
    )
  );
