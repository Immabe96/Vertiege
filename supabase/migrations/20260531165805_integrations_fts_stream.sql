-- Integrations: Postgres FTS for resident search + Stream user mapping.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('english', coalesce(name, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(bio, '')), 'B') ||
    setweight(to_tsvector('english', coalesce(profession, '')), 'C')
  ) STORED;

CREATE INDEX IF NOT EXISTS profiles_search_vector_idx
  ON public.profiles USING gin (search_vector);

CREATE OR REPLACE FUNCTION public.search_residents(
  p_query text,
  p_limit int DEFAULT 30
)
RETURNS TABLE (
  id text,
  name text,
  avatar_url text,
  bio_snippet text,
  rank real
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT
    p.id,
    p.name,
    p.avatar_url,
    ts_headline('english', coalesce(p.bio, ''), plainto_tsquery('english', p_query)) AS bio_snippet,
    ts_rank(p.search_vector, plainto_tsquery('english', p_query))::real AS rank
  FROM public.profiles p
  WHERE p.search_vector @@ plainto_tsquery('english', p_query)
  ORDER BY rank DESC
  LIMIT greatest(1, least(p_limit, 50));
$$;

REVOKE ALL ON FUNCTION public.search_residents(text, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.search_residents(text, int) TO authenticated;

CREATE TABLE IF NOT EXISTS public.stream_chat_users (
  user_id text PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  stream_user_id text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.stream_chat_users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS stream_chat_users_self_read ON public.stream_chat_users;
CREATE POLICY stream_chat_users_self_read ON public.stream_chat_users
  FOR SELECT TO authenticated
  USING (user_id = auth.uid()::text);

DROP POLICY IF EXISTS stream_chat_users_self_insert ON public.stream_chat_users;
CREATE POLICY stream_chat_users_self_insert ON public.stream_chat_users
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid()::text);

DROP POLICY IF EXISTS stream_chat_users_self_update ON public.stream_chat_users;
CREATE POLICY stream_chat_users_self_update ON public.stream_chat_users
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid()::text)
  WITH CHECK (user_id = auth.uid()::text);

COMMENT ON TABLE public.stream_chat_users IS
  'Stream Chat identity mapping; tokens issued by stream-token edge function.';;
