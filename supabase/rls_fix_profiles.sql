-- ═══════════════════════════════════════════════════════════════
-- Vertiege — Critical Fixes (run this in Supabase SQL Editor)
-- ═══════════════════════════════════════════════════════════════

-- 1. Allow authenticated users to create their own profile row
DROP POLICY IF EXISTS profiles_auth_insert ON profiles;
CREATE POLICY profiles_auth_insert ON profiles
  FOR INSERT
  WITH CHECK (id = auth.uid());

-- 2. Reaction RPC (missing from fresh_start.sql)
CREATE OR REPLACE FUNCTION toggle_reaction(
  post_id     TEXT,
  emoji       TEXT,
  resident_id TEXT
) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  UPDATE posts
  SET reactions = jsonb_set(
    COALESCE(reactions, '{}'::jsonb),
    ARRAY[emoji],
    to_jsonb(COALESCE((reactions->>emoji)::int, 0) + 1)
  )
  WHERE id::text = post_id;
END; $$;

-- 3. Comment RPC (missing from fresh_start.sql)
CREATE OR REPLACE FUNCTION add_comment(
  post_id     TEXT,
  resident_id TEXT,
  content     TEXT
) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  UPDATE posts
  SET comments = COALESCE(comments, '[]'::jsonb) || jsonb_build_object(
    'id', gen_random_uuid()::text,
    'residentId', resident_id,
    'content', content,
    'timestamp', (EXTRACT(EPOCH FROM now()) * 1000)::BIGINT
  )::jsonb,
  comment_count = COALESCE(comment_count, 0) + 1
  WHERE id::text = post_id;
END; $$;
