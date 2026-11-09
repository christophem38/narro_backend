-- 0080 : ORGANISATIONS (équipes d'entreprise) — rôles, droits, invitations.
--
-- CONTEXTE : jusqu'ici 1 compte = 1 personne = 1 voix = 1 abonnement. Seule
-- brique collective : la relecture d'équipe (0049), rattachée à la main par le
-- super-admin. Cette migration pose le socle de l'offre « entreprise » :
--
--   elocia_organizations      l'entreprise + sa voix (renseignée à l'onboarding
--                             entreprise)
--   elocia_org_members        qui en fait partie, avec un RÔLE (administrateur /
--                             rédacteur / relecteur / invité) et des DROITS
--                             ajustables un par un (les 4 rôles ne sont que des
--                             préréglages)
--   elocia_org_invitations    invitations par e-mail (jeton à usage unique)
--
-- PRINCIPE DE SÉCURITÉ : on n'AJOUTE que des politiques. Les règles actuelles
-- (self_read : chacun ne voit que ses propres données) ne bougent pas, donc un
-- compte solo n'est touché en rien. Les écritures sur les 3 nouvelles tables
-- passent par le service_role (actions serveur, contrôles applicatifs) : aucune
-- politique d'écriture n'est donnée aux utilisateurs.
--
-- Modèle many-to-many dès le départ (un compte peut appartenir à plusieurs
-- organisations — ouvre plus tard l'offre agence).
--
-- ROLE « admin » plateforme : l'équipe Élocia est super_admin uniquement.
-- Les comptes encore « admin » sont donc ramenés en super_admin ; « Administrateur »
-- ne désigne plus que le rôle d'entreprise (elocia_org_members.role).
--
-- RETOUR ARRIÈRE : drop table elocia_org_invitations, elocia_org_members,
-- elocia_organizations cascade; drop function elocia_org_right, elocia_my_org_ids,
-- elocia_is_org_admin, elocia_is_org_member; supprimer les policies org_*.
-- Idempotente.

-- 0) Rôle plateforme ----------------------------------------------------------
update public.elocia_profiles set role = 'super_admin' where role = 'admin';

-- 1) Tables -------------------------------------------------------------------
create table if not exists public.elocia_organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 1 and 120),
  created_by uuid references public.elocia_profiles(id) on delete set null,
  -- Voix de l'entreprise (onboarding entreprise)
  sector text,
  website text,
  description text,
  audiences text[] not null default '{}',
  tone text,
  territories text[] not null default '{}',
  taboo text,
  onboarding_completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.elocia_org_members (
  org_id uuid not null references public.elocia_organizations(id) on delete cascade,
  user_id uuid not null references public.elocia_profiles(id) on delete cascade,
  role text not null default 'redacteur'
    check (role in ('admin', 'redacteur', 'relecteur', 'invite')),
  -- Droits (les rôles ne sont que des préréglages ; l'administrateur les ajuste)
  can_write boolean not null default false,
  can_review boolean not null default false,
  can_edit_voice boolean not null default false,
  can_see_others boolean not null default false,
  -- Posture de parole choisie par la personne (onboarding rédacteur)
  posture text check (posture in ('entreprise', 'collaborateur', 'alterne')),
  created_at timestamptz not null default now(),
  primary key (org_id, user_id)
);
create index if not exists elocia_org_members_user_idx
  on public.elocia_org_members (user_id);

create table if not exists public.elocia_org_invitations (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.elocia_organizations(id) on delete cascade,
  email text not null,
  role text not null default 'redacteur'
    check (role in ('admin', 'redacteur', 'relecteur', 'invite')),
  can_write boolean not null default false,
  can_review boolean not null default false,
  can_edit_voice boolean not null default false,
  can_see_others boolean not null default false,
  token text not null unique,
  invited_by uuid references public.elocia_profiles(id) on delete set null,
  expires_at timestamptz not null default (now() + interval '14 days'),
  accepted_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists elocia_org_invitations_org_idx
  on public.elocia_org_invitations (org_id);
create index if not exists elocia_org_invitations_email_idx
  on public.elocia_org_invitations (lower(email));

-- 2) Fonctions d'appartenance (SECURITY DEFINER : évite la récursion RLS, cf. 0004)
create or replace function public.elocia_my_org_ids()
returns setof uuid
language sql stable security definer set search_path = public as $$
  select org_id from public.elocia_org_members where user_id = auth.uid();
$$;
revoke all on function public.elocia_my_org_ids() from public;
grant execute on function public.elocia_my_org_ids() to authenticated;

create or replace function public.elocia_is_org_member(org uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.elocia_org_members
    where org_id = org and user_id = auth.uid()
  );
$$;
revoke all on function public.elocia_is_org_member(uuid) from public;
grant execute on function public.elocia_is_org_member(uuid) to authenticated;

create or replace function public.elocia_is_org_admin(org uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.elocia_org_members
    where org_id = org and user_id = auth.uid() and role = 'admin'
  );
$$;
revoke all on function public.elocia_is_org_admin(uuid) from public;
grant execute on function public.elocia_is_org_admin(uuid) to authenticated;

-- L'utilisateur courant a-t-il ce droit sur le profil `target` ? (même organisation,
-- et droit coché pour l'utilisateur courant)
create or replace function public.elocia_org_right(target uuid, right_key text)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.elocia_org_members me
    join public.elocia_org_members them on them.org_id = me.org_id
    where me.user_id = auth.uid()
      and them.user_id = target
      and me.user_id <> them.user_id
      and case right_key
            when 'review' then me.can_review
            when 'see_others' then me.can_see_others
            else false
          end
  );
$$;
revoke all on function public.elocia_org_right(uuid, text) from public;
grant execute on function public.elocia_org_right(uuid, text) to authenticated;

-- 3) RLS des nouvelles tables (lecture seule pour les membres) ---------------
alter table public.elocia_organizations enable row level security;
alter table public.elocia_org_members enable row level security;
alter table public.elocia_org_invitations enable row level security;

drop policy if exists org_member_read on public.elocia_organizations;
create policy org_member_read on public.elocia_organizations
  for select to authenticated
  using (public.elocia_is_org_member(id));

drop policy if exists org_members_read on public.elocia_org_members;
create policy org_members_read on public.elocia_org_members
  for select to authenticated
  using (public.elocia_is_org_member(org_id));

drop policy if exists org_invitations_admin_read on public.elocia_org_invitations;
create policy org_invitations_admin_read on public.elocia_org_invitations
  for select to authenticated
  using (public.elocia_is_org_admin(org_id));

-- 4) Accès aux contenus des autres, selon les droits ------------------------
-- Relire : lire et faire avancer les posts SOUMIS (awaiting_validation).
drop policy if exists org_review_read on public.elocia_suggested_posts;
create policy org_review_read on public.elocia_suggested_posts
  for select to authenticated
  using (
    status = 'awaiting_validation'
    and public.elocia_org_right(profile_id, 'review')
  );

drop policy if exists org_review_update on public.elocia_suggested_posts;
create policy org_review_update on public.elocia_suggested_posts
  for update to authenticated
  using (
    status = 'awaiting_validation'
    and public.elocia_org_right(profile_id, 'review')
  )
  with check (
    status in ('approved', 'draft')
    and public.elocia_org_right(profile_id, 'review')
  );

-- Voir les autres : lecture seule des posts (brouillons compris) et des publiés.
drop policy if exists org_see_read on public.elocia_suggested_posts;
create policy org_see_read on public.elocia_suggested_posts
  for select to authenticated
  using (public.elocia_org_right(profile_id, 'see_others'));

drop policy if exists org_see_read on public.elocia_published_posts;
create policy org_see_read on public.elocia_published_posts
  for select to authenticated
  using (public.elocia_org_right(profile_id, 'see_others'));
