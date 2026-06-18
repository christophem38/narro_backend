-- 0018_super_admin_bootstrap_demo.sql
-- Promote 2 emails to super_admin et déclare les 7 emails de comptes
-- de démo (1 par offre). La création des users auth.users elle-même
-- est faite côté app via auth.admin.createUser (server action
-- ensureDemoUsers) car les hash bcrypt ne sont pas adressables en SQL.
-- 2026-06-15

-- 1) Bootstrap emails super_admin (idempotent)
insert into public.narro_super_admin_emails (email) values
  ('christophe.m@tfactory.fr'),
  ('a.matjabo@gmail.com')
on conflict (email) do nothing;

-- 2) Promouvoir les profils existants si déjà présents
update public.narro_profiles
   set role = 'super_admin',
       updated_at = now()
 where lower(email) in (
   'christophe.m@tfactory.fr',
   'a.matjabo@gmail.com',
   'cmurgue@gmail.com'
 )
   and role <> 'super_admin';
