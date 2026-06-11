-- Add auth wiring: per-user profiles, roles, RLS scoped to auth.uid().
-- Bootstrap super_admin via known emails.

-- 1) Role enum + columns on narro_profiles
do $$
begin
  if not exists (select 1 from pg_type where typname = 'narro_role') then
    create type public.narro_role as enum ('client','admin','super_admin');
  end if;
end$$;

alter table public.narro_profiles
  add column if not exists role public.narro_role not null default 'client',
  add column if not exists email text;

create index if not exists narro_profiles_role_idx on public.narro_profiles(role);
create index if not exists narro_profiles_email_idx on public.narro_profiles(email);

-- 2) Known super-admin emails (lower-case)
create table if not exists public.narro_super_admin_emails (
  email text primary key
);
insert into public.narro_super_admin_emails (email) values ('cmurgue@gmail.com')
  on conflict (email) do nothing;

-- 3) Trigger: when an auth user is created, create a matching narro_profiles row
create or replace function public.narro_handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  user_email text := lower(coalesce(new.email, ''));
  computed_role public.narro_role;
begin
  if exists (select 1 from public.narro_super_admin_emails where email = user_email) then
    computed_role := 'super_admin';
  else
    computed_role := 'client';
  end if;

  insert into public.narro_profiles (id, display_name, role_label, email, role, weekly_target, style_instructions)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data->>'display_name',''), split_part(new.email, '@', 1)),
    'Membre',
    user_email,
    computed_role,
    2,
    ''
  )
  on conflict (id) do update set
    email = excluded.email,
    role = case
      when public.narro_profiles.role = 'super_admin' then 'super_admin'
      else excluded.role
    end,
    updated_at = now();

  return new;
end$$;

drop trigger if exists narro_on_auth_user_created on auth.users;
create trigger narro_on_auth_user_created
  after insert on auth.users
  for each row execute function public.narro_handle_new_user();

-- 4) Tighten RLS — scope every table by profile_id = auth.uid()
--    admins/super_admins get read access to everything, mutations stay self-only.
do $$
declare
  t text;
  tables text[] := array[
    'narro_keywords','narro_tracked_influencers','narro_suggested_posts',
    'narro_news_sources','narro_network_influences','narro_published_posts','narro_events'
  ];
begin
  foreach t in array tables loop
    execute format('drop policy if exists demo_all on public.%I;', t);
    execute format('drop policy if exists self_read on public.%I;', t);
    execute format('drop policy if exists self_write on public.%I;', t);
    execute format('drop policy if exists self_update on public.%I;', t);
    execute format('drop policy if exists self_delete on public.%I;', t);
    execute format('drop policy if exists admin_read on public.%I;', t);

    execute format($f$
      create policy self_read on public.%I for select to authenticated
        using (
          profile_id = auth.uid()
          or exists (
            select 1 from public.narro_profiles p
            where p.id = auth.uid() and p.role in ('admin','super_admin')
          )
        );
    $f$, t);

    execute format($f$
      create policy self_write on public.%I for insert to authenticated
        with check (profile_id = auth.uid());
    $f$, t);

    execute format($f$
      create policy self_update on public.%I for update to authenticated
        using (profile_id = auth.uid())
        with check (profile_id = auth.uid());
    $f$, t);

    execute format($f$
      create policy self_delete on public.%I for delete to authenticated
        using (profile_id = auth.uid());
    $f$, t);
  end loop;
end$$;

-- 5) narro_profiles policies: users see self; admins see all; super_admins manage roles.
drop policy if exists demo_all on public.narro_profiles;
drop policy if exists self_read on public.narro_profiles;
drop policy if exists self_update on public.narro_profiles;
drop policy if exists admin_read on public.narro_profiles;
drop policy if exists super_admin_update_role on public.narro_profiles;

create policy self_read on public.narro_profiles for select to authenticated
  using (
    id = auth.uid()
    or exists (
      select 1 from public.narro_profiles p
      where p.id = auth.uid() and p.role in ('admin','super_admin')
    )
  );

create policy self_update on public.narro_profiles for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid() and role = (select role from public.narro_profiles where id = auth.uid()));

create policy super_admin_update_role on public.narro_profiles for update to authenticated
  using (
    exists (
      select 1 from public.narro_profiles p
      where p.id = auth.uid() and p.role = 'super_admin'
    )
  )
  with check (
    exists (
      select 1 from public.narro_profiles p
      where p.id = auth.uid() and p.role = 'super_admin'
    )
  );

-- 6) narro_super_admin_emails is super-admin-only (read/write)
alter table public.narro_super_admin_emails enable row level security;
drop policy if exists super_admin_only on public.narro_super_admin_emails;
create policy super_admin_only on public.narro_super_admin_emails for all to authenticated
  using (
    exists (
      select 1 from public.narro_profiles p
      where p.id = auth.uid() and p.role = 'super_admin'
    )
  )
  with check (
    exists (
      select 1 from public.narro_profiles p
      where p.id = auth.uid() and p.role = 'super_admin'
    )
  );

-- 7) RPC: super-admin can change another user's role
create or replace function public.narro_set_user_role(target_id uuid, new_role public.narro_role)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from public.narro_profiles where id = auth.uid() and role = 'super_admin') then
    raise exception 'forbidden';
  end if;
  update public.narro_profiles set role = new_role, updated_at = now() where id = target_id;
end$$;

revoke all on function public.narro_set_user_role(uuid, public.narro_role) from public;
grant execute on function public.narro_set_user_role(uuid, public.narro_role) to authenticated;

-- 8) Admin dashboard view: counts per profile
create or replace view public.narro_admin_user_stats as
select
  p.id,
  p.display_name,
  p.email,
  p.role,
  p.weekly_target,
  p.created_at,
  (select count(*) from public.narro_published_posts pp where pp.profile_id = p.id) as published_count,
  (select count(*) from public.narro_suggested_posts sp where sp.profile_id = p.id) as suggested_count,
  (select count(*) from public.narro_events ev where ev.profile_id = p.id) as events_count
from public.narro_profiles p;

grant select on public.narro_admin_user_stats to authenticated;
