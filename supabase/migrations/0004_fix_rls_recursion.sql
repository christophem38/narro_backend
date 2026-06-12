-- Fix infinite RLS recursion: every policy that checked "admin/super_admin"
-- via an EXISTS subquery on narro_profiles triggered the same policy again.
-- Replace with a SECURITY DEFINER helper that bypasses RLS to read the role.

create or replace function public.narro_current_role()
returns text
language sql
security definer
stable
set search_path = public
as $$
  select role::text from public.narro_profiles where id = auth.uid()
$$;

revoke all on function public.narro_current_role() from public;
grant execute on function public.narro_current_role() to anon, authenticated;

-- narro_profiles policies (rewrite to avoid recursion)
drop policy if exists self_read on public.narro_profiles;
drop policy if exists self_update on public.narro_profiles;
drop policy if exists super_admin_update_role on public.narro_profiles;

create policy self_read on public.narro_profiles for select to authenticated
  using (
    id = auth.uid()
    or public.narro_current_role() in ('admin','super_admin')
  );

create policy self_update on public.narro_profiles for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

create policy super_admin_update on public.narro_profiles for update to authenticated
  using (public.narro_current_role() = 'super_admin')
  with check (public.narro_current_role() = 'super_admin');

-- All other tables: rewrite self_read with the helper
do $$
declare
  t text;
  tables text[] := array[
    'narro_keywords','narro_tracked_influencers','narro_suggested_posts',
    'narro_news_sources','narro_network_influences','narro_published_posts','narro_events'
  ];
begin
  foreach t in array tables loop
    execute format('drop policy if exists self_read on public.%I;', t);
    execute format($f$
      create policy self_read on public.%I for select to authenticated
        using (
          profile_id = auth.uid()
          or public.narro_current_role() in ('admin','super_admin')
        );
    $f$, t);
  end loop;
end$$;

-- super_admin_emails: super-admin-only, via the helper
drop policy if exists super_admin_only on public.narro_super_admin_emails;
create policy super_admin_only on public.narro_super_admin_emails for all to authenticated
  using (public.narro_current_role() = 'super_admin')
  with check (public.narro_current_role() = 'super_admin');
