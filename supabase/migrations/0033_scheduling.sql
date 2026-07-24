-- 0033 : Calendrier — phase 2 (la planification devient un etat de premier ordre)
--
-- AVANT : « programmer » un post creait immediatement une ligne dans
--   elocia_published_posts avec status = 'Programmé' et une date future.
--   Consequences :
--     - le meme contenu existait deux fois (la suggestion restait en draft),
--     - la page Performances additionnait des posts jamais partis,
--     - aucun cron ne les publiait : ils restaient « Programmé » a vie.
--
-- APRES : la planification vit dans elocia_suggested_posts
--   (status = 'scheduled' + scheduled_for, colonne creee en 0014/0029 et
--   jamais utilisee jusqu'ici). elocia_published_posts ne contient plus que
--   du REELLEMENT publie, et n'est alimentee que par le cron de publication
--   ou par une declaration manuelle de l'utilisateur.
--
-- Idempotent.

-- =========================================================================
-- 1) Statut 'scheduled'
-- =========================================================================
do $$
begin
  if exists (select 1 from pg_constraint where conname = 'narro_suggested_posts_status_check') then
    alter table public.elocia_suggested_posts drop constraint narro_suggested_posts_status_check;
  end if;
  if exists (select 1 from pg_constraint where conname = 'elocia_suggested_posts_status_check') then
    alter table public.elocia_suggested_posts drop constraint elocia_suggested_posts_status_check;
  end if;
  alter table public.elocia_suggested_posts
    add constraint elocia_suggested_posts_status_check
    check (status in ('draft','awaiting_validation','approved','scheduled','published','expired'));
end$$;

-- =========================================================================
-- 2) Suivi de publication
-- =========================================================================
-- publish_mode : ce que le cron doit faire a l'echeance.
--   'auto'     -> publier sur LinkedIn via l'API (compte connecte)
--   'reminder' -> ne rien publier, juste faire remonter le post comme « du »
--                 (l'utilisateur publie a la main). C'est le mode impose aux
--                 profils sans compte LinkedIn connecte.
-- publish_state : etat anormal a signaler dans l'UI. null = rien a signaler.
--   'due'    -> l'echeance est passee, le post attend une action manuelle
--   'failed' -> la publication automatique a echoue (token expire, API KO,
--               echeance trop ancienne)
alter table public.elocia_suggested_posts
  add column if not exists publish_mode            text not null default 'auto',
  add column if not exists publish_state           text,
  add column if not exists publish_error           text,
  add column if not exists publish_attempts        smallint not null default 0,
  add column if not exists last_publish_attempt_at timestamptz,
  add column if not exists linkedin_post_urn       text;

do $$
begin
  if not exists (
    select 1 from pg_constraint
     where conname = 'elocia_suggested_posts_publish_mode_check'
  ) then
    alter table public.elocia_suggested_posts
      add constraint elocia_suggested_posts_publish_mode_check
      check (publish_mode in ('auto','reminder'));
  end if;
  if not exists (
    select 1 from pg_constraint
     where conname = 'elocia_suggested_posts_publish_state_check'
  ) then
    alter table public.elocia_suggested_posts
      add constraint elocia_suggested_posts_publish_state_check
      check (publish_state is null or publish_state in ('due','failed'));
  end if;
end$$;

-- Index de balayage du cron : il interroge TOUS les profils a la fois, donc
-- l'index (profile_id, scheduled_for) existant ne lui sert a rien.
create index if not exists elocia_suggested_posts_due_idx
  on public.elocia_suggested_posts (scheduled_for)
  where status = 'scheduled';

-- =========================================================================
-- 3) Backfill : rapatrier les posts programmes vers suggested_posts
-- =========================================================================

-- a) Programmes issus d'une suggestion : on rend la main a la suggestion.
update public.elocia_suggested_posts s
   set status        = 'scheduled',
       scheduled_for = p.scheduled_at,
       updated_at    = now()
  from public.elocia_published_posts p
 where p.origin_suggested_id = s.id
   and p.status = 'Programmé'
   and p.scheduled_at is not null;

-- b) Programmes sans suggestion source (rediges directement depuis le
--    generateur) : on materialise la suggestion correspondante.
--    week_offset / type / category sont NOT NULL sans defaut : on pose des
--    valeurs neutres, ces posts ne passent plus par le cycle hebdomadaire.
insert into public.elocia_suggested_posts (
  id, profile_id, week_offset, type, category, date_label,
  text, title, posture, angle, status, scheduled_for, ordinal
)
select
  'sched-' || p.id::text,
  p.profile_id,
  0,
  'actu',
  'Programmé',
  to_char(p.scheduled_at, 'DD/MM/YYYY'),
  p.content,
  p.title,
  p.posture,
  p.angle,
  'scheduled',
  p.scheduled_at,
  0
  from public.elocia_published_posts p
 where p.status = 'Programmé'
   and p.scheduled_at is not null
   and p.origin_suggested_id is null
on conflict (id) do nothing;

-- c) L'historique de publication ne garde que du reellement publie.
delete from public.elocia_published_posts
 where status = 'Programmé'
   and scheduled_at is not null;

-- d) SECURITE — ne jamais publier retroactivement.
--    Aucun cron n'a jamais tourne : certains posts « programmes » ont une
--    echeance vieille de plusieurs mois. Sans ce garde-fou, la mise en
--    service du cron les enverrait tous sur LinkedIn d'un coup. On les marque
--    en echec explicite : l'utilisateur decide de les replanifier ou non.
update public.elocia_suggested_posts
   set publish_state = 'failed',
       publish_error = 'Échéance dépassée avant la mise en service de la publication automatique — à replanifier.'
 where status = 'scheduled'
   and scheduled_for < now()
   and publish_state is null;
