-- Vertiege Forui + hybrid backend persistence hardening.
-- Additive migration: keeps the existing TEXT id schema while making social
-- actions server-authoritative and safe for optimistic replay.

ALTER TABLE public.posts
  ADD COLUMN IF NOT EXISTS mentions JSONB NOT NULL DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS hashtags JSONB NOT NULL DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS poll JSONB,
  ADD COLUMN IF NOT EXISTS scheduled_for TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

ALTER TABLE public.worlds
  ADD COLUMN IF NOT EXISTS visibility TEXT NOT NULL DEFAULT 'public';

CREATE TABLE IF NOT EXISTS public.bookmarks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE,
  resident_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE,
  post_id TEXT NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT bookmarks_actor_present CHECK (
    user_id IS NOT NULL OR resident_id IS NOT NULL
  )
);

ALTER TABLE public.bookmarks
  ADD COLUMN IF NOT EXISTS user_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS resident_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS post_id TEXT REFERENCES public.posts(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();

ALTER TABLE public.bookmarks
  DROP CONSTRAINT IF EXISTS bookmarks_actor_present;

ALTER TABLE public.bookmarks
  ADD CONSTRAINT bookmarks_actor_present CHECK (
    user_id IS NOT NULL OR resident_id IS NOT NULL
  );

DROP INDEX IF EXISTS public.bookmarks_user_post_unique;
CREATE UNIQUE INDEX IF NOT EXISTS bookmarks_user_post_unique
  ON public.bookmarks (COALESCE(user_id, resident_id), post_id);
CREATE INDEX IF NOT EXISTS idx_bookmarks_post ON public.bookmarks(post_id);
CREATE INDEX IF NOT EXISTS idx_bookmarks_user ON public.bookmarks(user_id);
CREATE INDEX IF NOT EXISTS idx_bookmarks_resident ON public.bookmarks(resident_id);

ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.device_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  resident_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  platform TEXT NOT NULL DEFAULT 'unknown',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_resident
  ON public.device_tokens(resident_id);

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "posts_read" ON public.posts;
DROP POLICY IF EXISTS "posts_insert" ON public.posts;
DROP POLICY IF EXISTS "posts_author_delete" ON public.posts;
DROP POLICY IF EXISTS "posts_council_delete" ON public.posts;
DROP POLICY IF EXISTS "posts_council_update" ON public.posts;
DROP POLICY IF EXISTS "posts_author_update" ON public.posts;

CREATE POLICY "posts_read" ON public.posts
  FOR SELECT
  USING (
    deleted_at IS NULL
    AND (
      public.is_world_member(world_id)
      OR EXISTS (
        SELECT 1 FROM public.worlds
        WHERE worlds.id = posts.world_id
          AND COALESCE(worlds.visibility, 'public') = 'public'
      )
    )
  );

CREATE POLICY "posts_insert" ON public.posts
  FOR INSERT
  WITH CHECK (
    resident_id = auth.uid()::text
    AND public.is_world_member(world_id)
  );

CREATE POLICY "posts_author_update" ON public.posts
  FOR UPDATE
  USING (resident_id = auth.uid()::text)
  WITH CHECK (resident_id = auth.uid()::text);

CREATE POLICY "posts_council_update" ON public.posts
  FOR UPDATE
  USING (public.is_council_or_above(world_id))
  WITH CHECK (public.is_council_or_above(world_id));

CREATE POLICY "posts_author_delete" ON public.posts
  FOR DELETE
  USING (resident_id = auth.uid()::text);

CREATE POLICY "posts_council_delete" ON public.posts
  FOR DELETE
  USING (public.is_council_or_above(world_id));

DROP POLICY IF EXISTS "bookmarks_read_own" ON public.bookmarks;
DROP POLICY IF EXISTS "bookmarks_insert_own" ON public.bookmarks;
DROP POLICY IF EXISTS "bookmarks_delete_own" ON public.bookmarks;

CREATE POLICY "bookmarks_read_own" ON public.bookmarks
  FOR SELECT
  USING (COALESCE(user_id, resident_id) = auth.uid()::text);

CREATE POLICY "bookmarks_insert_own" ON public.bookmarks
  FOR INSERT
  WITH CHECK (COALESCE(user_id, resident_id) = auth.uid()::text);

CREATE POLICY "bookmarks_delete_own" ON public.bookmarks
  FOR DELETE
  USING (COALESCE(user_id, resident_id) = auth.uid()::text);

DROP POLICY IF EXISTS "device_tokens_read_own" ON public.device_tokens;
DROP POLICY IF EXISTS "device_tokens_upsert_own" ON public.device_tokens;
DROP POLICY IF EXISTS "device_tokens_delete_own" ON public.device_tokens;

CREATE POLICY "device_tokens_read_own" ON public.device_tokens
  FOR SELECT
  USING (resident_id = auth.uid()::text);

CREATE POLICY "device_tokens_upsert_own" ON public.device_tokens
  FOR INSERT
  WITH CHECK (resident_id = auth.uid()::text);

CREATE POLICY "device_tokens_update_own" ON public.device_tokens
  FOR UPDATE
  USING (resident_id = auth.uid()::text)
  WITH CHECK (resident_id = auth.uid()::text);

CREATE POLICY "device_tokens_delete_own" ON public.device_tokens
  FOR DELETE
  USING (resident_id = auth.uid()::text);

CREATE OR REPLACE FUNCTION public.toggle_post_reaction_v2(
  p_post_id TEXT,
  p_emoji TEXT,
  p_resident_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  current_reactions JSONB;
  users_for_emoji JSONB;
  next_reactions JSONB;
BEGIN
  IF p_resident_id <> auth.uid()::text THEN
    RAISE EXCEPTION 'Cannot react for another resident' USING ERRCODE = '42501';
  END IF;

  SELECT COALESCE(reactions, '{}'::jsonb)
    INTO current_reactions
  FROM public.posts
  WHERE id = p_post_id
  FOR UPDATE;

  IF current_reactions IS NULL THEN
    RAISE EXCEPTION 'Post not found' USING ERRCODE = 'P0002';
  END IF;

  users_for_emoji := COALESCE(current_reactions -> p_emoji, '[]'::jsonb);

  IF jsonb_typeof(users_for_emoji) <> 'array' THEN
    users_for_emoji := '[]'::jsonb;
  END IF;

  IF users_for_emoji ? p_resident_id THEN
    users_for_emoji := (
      SELECT COALESCE(jsonb_agg(value), '[]'::jsonb)
      FROM jsonb_array_elements_text(users_for_emoji) AS value
      WHERE value <> p_resident_id
    );
  ELSE
    users_for_emoji := users_for_emoji || to_jsonb(p_resident_id);
  END IF;

  IF jsonb_array_length(users_for_emoji) = 0 THEN
    next_reactions := current_reactions - p_emoji;
  ELSE
    next_reactions := jsonb_set(current_reactions, ARRAY[p_emoji], users_for_emoji, true);
  END IF;

  UPDATE public.posts
  SET reactions = next_reactions
  WHERE id = p_post_id;

  RETURN next_reactions;
END;
$$;

CREATE OR REPLACE FUNCTION public.add_post_comment_v2(
  p_post_id TEXT,
  p_comment_id TEXT,
  p_resident_id TEXT,
  p_resident_name TEXT,
  p_content TEXT,
  p_parent_id TEXT DEFAULT NULL,
  p_tier_at_posting INT DEFAULT 1
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  next_comments JSONB;
BEGIN
  IF p_resident_id <> auth.uid()::text THEN
    RAISE EXCEPTION 'Cannot comment for another resident' USING ERRCODE = '42501';
  END IF;

  UPDATE public.posts
  SET
    comments = COALESCE(comments, '[]'::jsonb) || jsonb_build_object(
      'id', p_comment_id,
      'residentId', p_resident_id,
      'residentName', p_resident_name,
      'content', p_content,
      'timestamp', (EXTRACT(EPOCH FROM now()) * 1000)::bigint,
      'parentId', p_parent_id,
      'tierAtPosting', p_tier_at_posting
    ),
    comment_count = COALESCE(comment_count, 0) + 1
  WHERE id = p_post_id
  RETURNING comments INTO next_comments;

  IF next_comments IS NULL THEN
    RAISE EXCEPTION 'Post not found' USING ERRCODE = 'P0002';
  END IF;

  RETURN next_comments;
END;
$$;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.posts TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.bookmarks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.device_tokens TO authenticated;
GRANT EXECUTE ON FUNCTION public.toggle_post_reaction_v2(TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.add_post_comment_v2(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, INT) TO authenticated;

DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.bookmarks;
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;

  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.device_tokens;
  EXCEPTION WHEN duplicate_object THEN
    NULL;
  END;
END $$;
