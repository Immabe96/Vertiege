-- ═══════════════════════════════════════════════════════════════
-- 20260516_create_bookmarks_table.sql
-- Cloud-synced bookmarks for posts
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  post_id TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, post_id)
);

CREATE INDEX IF NOT EXISTS idx_bookmarks_user_id ON public.bookmarks(user_id);
CREATE INDEX IF NOT EXISTS idx_bookmarks_post_id ON public.bookmarks(post_id);

ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "bookmarks_read_own" ON public.bookmarks;
CREATE POLICY "bookmarks_read_own" ON public.bookmarks
  FOR SELECT USING (user_id = auth.uid()::text);

DROP POLICY IF EXISTS "bookmarks_insert_own" ON public.bookmarks;
CREATE POLICY "bookmarks_insert_own" ON public.bookmarks
  FOR INSERT WITH CHECK (user_id = auth.uid()::text);

DROP POLICY IF EXISTS "bookmarks_delete_own" ON public.bookmarks;
CREATE POLICY "bookmarks_delete_own" ON public.bookmarks
  FOR DELETE USING (user_id = auth.uid()::text);
