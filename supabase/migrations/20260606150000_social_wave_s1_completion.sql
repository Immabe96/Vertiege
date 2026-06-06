-- Wave S1 completion: published feed filter, server-side social notifications

-- ─── Published-only Nexus pagination ───
CREATE OR REPLACE FUNCTION public.list_posts_cursor(
  p_world_id TEXT,
  p_cursor TIMESTAMPTZ DEFAULT NULL,
  p_limit INT DEFAULT 20
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_limit INT;
  v_rows JSONB;
  v_has_more BOOLEAN;
BEGIN
  IF NOT public.is_world_member(p_world_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not a member of this world');
  END IF;

  v_limit := LEAST(GREATEST(COALESCE(p_limit, 20), 1), 50);

  SELECT COALESCE(jsonb_agg(to_jsonb(p) ORDER BY p.created_at DESC), '[]'::jsonb)
  INTO v_rows
  FROM (
    SELECT *
    FROM public.posts
    WHERE world_id = p_world_id
      AND status = 'published'
      AND (p_cursor IS NULL OR created_at < p_cursor)
    ORDER BY created_at DESC
    LIMIT v_limit + 1
  ) p;

  v_has_more := jsonb_array_length(v_rows) > v_limit;
  IF v_has_more THEN
    v_rows := (
      SELECT jsonb_agg(elem)
      FROM (
        SELECT elem
        FROM jsonb_array_elements(v_rows) WITH ORDINALITY AS t(elem, ord)
        WHERE ord <= v_limit
      ) s
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'items', COALESCE(v_rows, '[]'::jsonb),
    'has_more', v_has_more,
    'next_cursor', (
      SELECT (elem->>'created_at')::timestamptz
      FROM jsonb_array_elements(COALESCE(v_rows, '[]'::jsonb)) AS elem
      ORDER BY (elem->>'created_at')::timestamptz ASC
      LIMIT 1
    )
  );
END;
$$;

-- ─── Notify post author (skip self) ───
CREATE OR REPLACE FUNCTION public.notify_post_author_social(
  p_post_id TEXT,
  p_type TEXT,
  p_message TEXT,
  p_dedupe_key TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_author TEXT;
  v_world_id TEXT;
  v_actor TEXT;
  v_id TEXT;
BEGIN
  v_actor := auth.uid()::text;
  IF v_actor IS NULL THEN
    RETURN;
  END IF;

  SELECT resident_id, world_id
  INTO v_author, v_world_id
  FROM public.posts
  WHERE id = p_post_id;

  IF v_author IS NULL OR v_author = v_actor THEN
    RETURN;
  END IF;

  v_id := COALESCE(
    NULLIF(trim(p_dedupe_key), ''),
    p_type || '-' || p_post_id || '-' || v_actor || '-' || floor(extract(epoch from now()))::text
  );

  INSERT INTO public.notifications (
    id,
    recipient_id,
    type,
    message,
    world_id,
    post_id,
    read,
    created_at
  ) VALUES (
    v_id,
    v_author,
    p_type,
    p_message,
    v_world_id,
    p_post_id,
    false,
    now()
  )
  ON CONFLICT (id) DO NOTHING;
END;
$$;

REVOKE ALL ON FUNCTION public.notify_post_author_social(TEXT, TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.notify_post_author_social(TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- ─── Reactions: notify on add only ───
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
  was_reacting BOOLEAN;
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

  was_reacting := users_for_emoji ? p_resident_id;

  IF was_reacting THEN
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

  IF NOT was_reacting THEN
    PERFORM public.notify_post_author_social(
      p_post_id,
      'like',
      'Someone reacted to your post',
      'like-' || p_post_id || '-' || p_resident_id
    );
  END IF;

  RETURN next_reactions;
END;
$$;

-- ─── Comments: notify author ───
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

  PERFORM public.notify_post_author_social(
    p_post_id,
    'comment',
    'Someone commented on your post',
    'comment-' || p_comment_id
  );

  RETURN next_comments;
END;
$$;
