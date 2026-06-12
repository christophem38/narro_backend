-- Allow each suggested post to carry a visual_data JSON describing what to
-- render in the visual block (quote text, chart bars, carousel slides,
-- image search query). The visual_type column already says which shape.

alter table public.narro_suggested_posts
  add column if not exists visual_data jsonb;
