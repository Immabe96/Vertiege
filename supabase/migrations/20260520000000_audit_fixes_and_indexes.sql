-- Vertiege Jules Full App Audit Fixes and Indexes (20260520)
-- ═══════════════════════════════════════════════════════════════
-- 1. Add missing indexes and constraints
-- ═══════════════════════════════════════════════════════════════

-- Channel lookup by world and default status
CREATE INDEX IF NOT EXISTS idx_channels_world_default ON public.channels(world_id) WHERE is_default = true;

-- Post feed queries by world and created_at
CREATE INDEX IF NOT EXISTS idx_posts_world_created ON public.posts(world_id, created_at DESC);

-- Post feed queries by author and created_at
CREATE INDEX IF NOT EXISTS idx_posts_author_created ON public.posts(author_id, created_at DESC);

-- ═══════════════════════════════════════════════════════════════
-- 2. Audit RLS Policies (Fixing Channel Reads for Public Visibility)
-- ═══════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "channels_read" ON public.channels;

CREATE POLICY "channels_read" ON public.channels
  FOR SELECT
  USING (
    public.is_world_member(world_id)
    OR EXISTS (
      SELECT 1 FROM public.worlds
      WHERE worlds.id = channels.world_id
      AND COALESCE(worlds.visibility, 'public') = 'public'
    )
  );
