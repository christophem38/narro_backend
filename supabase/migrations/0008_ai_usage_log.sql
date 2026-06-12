-- Log every AI call (Anthropic, Perplexity, etc.) so the admin can monitor
-- token consumption and cost across all users.

create table if not exists public.narro_ai_calls (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references public.narro_profiles(id) on delete cascade,
  provider text not null check (provider in ('anthropic','perplexity','linkedin','openai')),
  model text not null default 'unknown',
  feature text not null,
  input_tokens int not null default 0,
  output_tokens int not null default 0,
  total_tokens int generated always as (input_tokens + output_tokens) stored,
  cost_usd numeric(12, 6) not null default 0,
  duration_ms int not null default 0,
  status text not null check (status in ('success','error')),
  error_message text,
  created_at timestamptz not null default now()
);

create index if not exists narro_ai_calls_profile_idx
  on public.narro_ai_calls(profile_id, created_at desc);
create index if not exists narro_ai_calls_provider_idx
  on public.narro_ai_calls(provider, created_at desc);
create index if not exists narro_ai_calls_feature_idx
  on public.narro_ai_calls(feature, created_at desc);

alter table public.narro_ai_calls enable row level security;

drop policy if exists self_read on public.narro_ai_calls;
drop policy if exists admin_read on public.narro_ai_calls;
drop policy if exists self_write on public.narro_ai_calls;

-- Users can read their own AI calls, admins read everything
create policy self_read on public.narro_ai_calls for select to authenticated
  using (profile_id = auth.uid() or public.narro_current_role() in ('admin','super_admin'));

-- Inserts are made from server actions running as the user
create policy self_write on public.narro_ai_calls for insert to authenticated
  with check (profile_id = auth.uid() or profile_id is null);

-- Aggregated view per profile for the admin dashboard
create or replace view public.narro_ai_usage_per_profile as
select
  p.id as profile_id,
  p.display_name,
  p.email,
  p.role,
  p.subscription_tier,
  coalesce(sum(case when c.status = 'success' then c.total_tokens else 0 end), 0)::bigint as total_tokens,
  coalesce(sum(case when c.status = 'success' then c.input_tokens else 0 end), 0)::bigint as input_tokens,
  coalesce(sum(case when c.status = 'success' then c.output_tokens else 0 end), 0)::bigint as output_tokens,
  coalesce(sum(c.cost_usd), 0)::numeric(12, 4) as total_cost_usd,
  count(c.id) filter (where c.status = 'success')::int as call_count,
  count(c.id) filter (where c.status = 'error')::int as error_count,
  max(c.created_at) as last_call_at
from public.narro_profiles p
left join public.narro_ai_calls c on c.profile_id = p.id
group by p.id, p.display_name, p.email, p.role, p.subscription_tier;

grant select on public.narro_ai_usage_per_profile to authenticated;

-- Aggregated view per provider/feature (overall + last 30d) for the admin
create or replace view public.narro_ai_usage_per_feature as
select
  provider,
  feature,
  count(*) filter (where status = 'success')::int as call_count,
  sum(case when status = 'success' then total_tokens else 0 end)::bigint as total_tokens,
  sum(cost_usd)::numeric(12, 4) as total_cost_usd
from public.narro_ai_calls
group by provider, feature
order by total_cost_usd desc;

grant select on public.narro_ai_usage_per_feature to authenticated;
