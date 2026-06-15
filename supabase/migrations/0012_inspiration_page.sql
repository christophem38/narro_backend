-- Inspiration page spec : source RSS metadata, V1 pertinence score (4 components),
-- 3 badges, Unsplash image with photographer credit, status 'awaiting_validation'.

alter table public.narro_suggested_posts
  -- Source (article from RSS)
  add column if not exists source_title text,
  add column if not exists source_url text,
  add column if not exists source_media_name text,
  add column if not exists source_date date,
  add column if not exists source_meta_description text,

  -- Badges (theme / audience / objective)
  add column if not exists theme_badge text,
  add column if not exists audience_badge text,
  add column if not exists objective_badge text,

  -- Pertinence V1 score (single % + 4 components)
  add column if not exists pertinence_pct int default 0
    check (pertinence_pct between 0 and 100),
  add column if not exists score_pillars int default 0
    check (score_pillars between 0 and 40),
  add column if not exists score_sector int default 0
    check (score_sector between 0 and 30),
  add column if not exists score_audience int default 0
    check (score_audience between 0 and 20),
  add column if not exists score_network int default 0
    check (score_network between 0 and 10),

  -- Image (Unsplash / Pexels)
  add column if not exists image_url text,
  add column if not exists image_credit_name text,
  add column if not exists image_credit_url text,
  add column if not exists image_credit_source text default 'unsplash',
  add column if not exists image_query text,
  add column if not exists image_validated boolean default false,

  -- Hashtags as a dedicated field for clarity (still optional)
  add column if not exists hashtags text,

  -- Indicator : the user edited the content compared to the generated version
  add column if not exists is_modified boolean default false;

-- Add 'awaiting_validation' to the status check
do $$
begin
  if exists (
    select 1 from pg_constraint where conname = 'narro_suggested_posts_status_check'
  ) then
    alter table public.narro_suggested_posts
      drop constraint narro_suggested_posts_status_check;
  end if;
end$$;

alter table public.narro_suggested_posts
  add constraint narro_suggested_posts_status_check
  check (status in ('draft','awaiting_validation','published','expired'));
