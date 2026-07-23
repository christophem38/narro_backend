-- 0027 : rattrapage du rebrand Narro -> Elocia (fonctions, RPC, colonne, vues, board)
--
-- Contexte : la migration 0024 a renommé les TABLES narro_* -> elocia_* mais :
--   - n'a pas réécrit le CORPS des fonctions plpgsql (références en dur),
--   - n'a pas renommé les fonctions appelées en RPC par le code (elocia_*),
--   - certaines migrations (0023, 0026) n'ont jamais été appliquées.
-- Cette migration est idempotente : réexécutable sans risque.

-- (1) Colonne manquante (migration 0023 non appliquée)
alter table public.elocia_profiles
  add column if not exists inclusive_writing boolean;

-- (2) Vues restées en narro_ (le code lit elocia_*)
alter view if exists public.narro_admin_user_stats     rename to elocia_admin_user_stats;
alter view if exists public.narro_ai_usage_per_feature rename to elocia_ai_usage_per_feature;
alter view if exists public.narro_ai_usage_per_profile rename to elocia_ai_usage_per_profile;

-- (3) Fonctions appelées par triggers/policies : on GARDE le nom narro_
--     (sinon on casse triggers/policies), on corrige seulement le CORPS -> elocia_*.
create or replace function public.narro_current_role()
returns text language sql stable security definer set search_path = public
as $$ select role::text from public.elocia_profiles where id = auth.uid() $$;
revoke all on function public.narro_current_role() from public;
grant execute on function public.narro_current_role() to anon, authenticated;

create or replace function public.narro_seed_progress_plan(p_profile_id uuid)
returns void language plpgsql security definer set search_path = public
as $$
begin
  delete from public.elocia_progress_tasks where profile_id = p_profile_id;
  insert into public.elocia_progress_tasks (profile_id, month_index, ordinal, title) values
    (p_profile_id, 1, 0, 'Réagir à une actualité de votre secteur'),
    (p_profile_id, 1, 1, 'Commenter une tendance émergente'),
    (p_profile_id, 1, 2, 'Partager un apprentissage simple'),
    (p_profile_id, 1, 3, 'Installer un rythme : 1 post / semaine'),
    (p_profile_id, 2, 0, 'Analyse marché : poser un point de vue'),
    (p_profile_id, 2, 1, 'Retour d''expérience sur un projet récent'),
    (p_profile_id, 2, 2, 'Décrypter un sujet sectoriel'),
    (p_profile_id, 2, 3, 'Passer à 2 posts / semaine'),
    (p_profile_id, 3, 0, 'Opinion personnelle assumée sur un sujet clivant'),
    (p_profile_id, 3, 1, 'Leadership sectoriel : proposer une vision'),
    (p_profile_id, 3, 2, 'Vision long terme : raconter votre cap'),
    (p_profile_id, 3, 3, 'Tenir 2-3 posts / semaine');
end$$;

create or replace function public.narro_brand_completude(p_profile uuid)
returns numeric language sql stable
as $$
  with parts as (
    select 0.20 as weight, case when exists (
      select 1 from public.elocia_brand_voice v where v.profile_id = p_profile
        and (v.posture is not null or v.recommended_tone is not null)) then 1 else 0 end as score
    union all select 0.20, case when exists (select 1 from public.elocia_brand_territories  where profile_id = p_profile limit 1) then 1 else 0 end
    union all select 0.20, case when exists (select 1 from public.elocia_brand_key_messages where profile_id = p_profile limit 1) then 1 else 0 end
    union all select 0.20, case when exists (select 1 from public.elocia_brand_evidences    where profile_id = p_profile limit 1) then 1 else 0 end
    union all select 0.20, case when exists (select 1 from public.elocia_brand_guardrails   where profile_id = p_profile limit 1) then 1 else 0 end
  )
  select coalesce(sum(weight * score), 0) from parts;
$$;

-- (4) RPC attendues par le code sous le nom elocia_* (sb.rpc("elocia_..."))
create or replace function public.elocia_set_user_role(target_id uuid, new_role narro_role)
returns void language plpgsql security definer set search_path = public
as $$
begin
  if not exists (select 1 from public.elocia_profiles where id = auth.uid() and role = 'super_admin') then
    raise exception 'forbidden';
  end if;
  update public.elocia_profiles set role = new_role, updated_at = now() where id = target_id;
end$$;
revoke all on function public.elocia_set_user_role(uuid, narro_role) from public;
grant execute on function public.elocia_set_user_role(uuid, narro_role) to authenticated;

create or replace function public.elocia_import_demo()
returns void language plpgsql security definer set search_path = public
as $$
declare
  demo uuid := '00000000-0000-0000-0000-000000000001';
  me   uuid := auth.uid();
begin
  if me is null then raise exception 'not authenticated'; end if;
  insert into public.elocia_keywords (profile_id, label)
    select me, label from public.elocia_keywords where profile_id = demo on conflict do nothing;
  insert into public.elocia_tracked_influencers (profile_id, handle, tag, profile_url)
    select me, handle, tag, profile_url from public.elocia_tracked_influencers where profile_id = demo on conflict do nothing;
  insert into public.elocia_suggested_posts
    (id, profile_id, week_offset, type, category, date_label, text, visual_type, title, posture, angle, status, ordinal, pertinence_scores, exposure_level)
    select id || '-' || substr(me::text,1,8), me, week_offset, type, category, date_label, text, visual_type, title, posture, angle, status, ordinal, pertinence_scores, exposure_level
    from public.elocia_suggested_posts where profile_id = demo on conflict do nothing;
  insert into public.elocia_news_sources (id, profile_id, week_offset, category, title, origin, logo, url, ordinal)
    select id || '-' || substr(me::text,1,8), me, week_offset, category, title, origin, logo, url, ordinal
    from public.elocia_news_sources where profile_id = demo on conflict do nothing;
  insert into public.elocia_network_influences (id, profile_id, week_offset, user_handle, tag, text, logo, url, ordinal)
    select id || '-' || substr(me::text,1,8), me, week_offset, user_handle, tag, text, logo, url, ordinal
    from public.elocia_network_influences where profile_id = demo on conflict do nothing;
  insert into public.elocia_events (profile_id, title, description, suggested_text, event_date, event_type, status)
    select me, title, description, suggested_text, event_date, event_type, status from public.elocia_events where profile_id = demo;
  insert into public.elocia_published_posts (profile_id, title, content, posture, angle, status, published_at, like_count, share_count, comment_count, reach_count)
    select me, title, content, posture, angle, status, published_at, 12, 3, 5, 800 from public.elocia_published_posts where profile_id = demo;
  update public.elocia_profiles set
      sector = coalesce(sector,'SaaS B2B'),
      target_audience = coalesce(target_audience,'Dirigeants & RH'),
      primary_objective = coalesce(primary_objective,'Renforcer ma crédibilité sectorielle'),
      tone_preset = coalesce(tone_preset,'expert'),
      editorial_user_tag = coalesce(editorial_user_tag,'@MarcSimon'),
      onboarded = true, updated_at = now()
    where id = me;
end$$;
revoke all on function public.elocia_import_demo() from public;
grant execute on function public.elocia_import_demo() to authenticated;

-- Anciennes fonctions devenues mortes (le code n'appelle plus que elocia_*)
drop function if exists public.narro_set_user_role(uuid, narro_role);
drop function if exists public.narro_import_demo();

-- (5) Table board (migration 0026 non appliquée)
create table if not exists public.board (
  id         text primary key,
  content    text not null default '',
  updated_at timestamptz not null default now()
);
alter table public.board enable row level security;
