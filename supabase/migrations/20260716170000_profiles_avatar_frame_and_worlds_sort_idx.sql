-- Cosmetics / member embeds expect profiles.avatar_frame_id.
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS avatar_frame_id TEXT;

CREATE INDEX IF NOT EXISTS idx_worlds_sort_order
  ON public.worlds (sort_order ASC NULLS LAST, created_at DESC);
