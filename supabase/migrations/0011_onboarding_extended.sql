-- 8-step onboarding fields. Each step maps to a group of columns below.

alter table public.narro_profiles
  -- Step 1 : profil professionnel
  add column if not exists speaker_type text default 'self'
    check (speaker_type in ('self','executive','expert','team','client')),
  add column if not exists first_name text,
  add column if not exists last_name text,
  add column if not exists job_title text,
  add column if not exists seniority_level text
    check (seniority_level is null or seniority_level in ('c_level','head_of','manager','expert','founder','other')),
  add column if not exists company_name text,
  add column if not exists linkedin_input_url text,

  -- Step 2 : entreprise
  add column if not exists company_website text,
  add column if not exists company_description text,

  -- Step 3 : posture
  add column if not exists editorial_posture text
    check (editorial_posture is null or editorial_posture in ('leader_opinion','expert','accessible_leader','spokesperson','business_creator')),
  add column if not exists postures_to_avoid text,

  -- Step 4 : objectifs
  add column if not exists objectives text[] not null default '{}',
  add column if not exists priority_objective_90d text,

  -- Step 5 : audience
  add column if not exists target_audiences text[] not null default '{}',
  add column if not exists audience_maturity text
    check (audience_maturity is null or audience_maturity in ('beginner','intermediate','expert','mixed')),

  -- Step 6 : voix éditoriale
  add column if not exists voice_tone text,
  add column if not exists address_form text default 'vous'
    check (address_form in ('tu','vous','adaptive')),
  add column if not exists writing_language text default 'fr',
  add column if not exists gender_agreement text default 'neutral'
    check (gender_agreement in ('feminine','masculine','neutral')),
  add column if not exists emoji_usage text default 'moderate'
    check (emoji_usage in ('none','minimal','moderate','free')),

  -- Step 7 : style
  add column if not exists style_setup_method text
    check (style_setup_method is null or style_setup_method in ('linkedin_import','paste_example','describe','recommended')),
  add column if not exists style_sample_post text,
  add column if not exists style_description text,

  -- Step 8 : sujets & sources
  add column if not exists topics_followed text[] not null default '{}',
  add column if not exists priority_sources text[] not null default '{}',
  add column if not exists suggestion_frequency text default 'weekly'
    check (suggestion_frequency in ('weekly','multi_weekly','on_demand'));
