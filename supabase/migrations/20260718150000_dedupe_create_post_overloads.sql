-- PostgREST returns HTTP 300 when multiple create_post signatures match the
-- same request (client omits p_repost_of). Keep a single canonical overload
-- that includes optional p_repost_of + scheduled_for support.

DROP FUNCTION IF EXISTS public.create_post(
  TEXT, TEXT, TEXT, JSONB, BOOLEAN, BOOLEAN, BOOLEAN, JSONB, JSONB, JSONB, TIMESTAMPTZ
);
DROP FUNCTION IF EXISTS public.create_post(
  TEXT, TEXT, TEXT, JSONB, BOOLEAN, BOOLEAN, BOOLEAN, JSONB, JSONB, JSONB, TIMESTAMPTZ, TEXT
);

CREATE OR REPLACE FUNCTION public.create_post(
  p_world_id TEXT,
  p_content TEXT,
  p_image_url TEXT DEFAULT NULL,
  p_media JSONB DEFAULT '[]'::jsonb,
  p_is_announcement BOOLEAN DEFAULT false,
  p_is_decree BOOLEAN DEFAULT false,
  p_is_pinned BOOLEAN DEFAULT false,
  p_poll JSONB DEFAULT NULL,
  p_mentions JSONB DEFAULT '[]'::jsonb,
  p_hashtags JSONB DEFAULT '[]'::jsonb,
  p_scheduled_for TIMESTAMPTZ DEFAULT NULL,
  p_repost_of TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id TEXT;
  v_post_id TEXT;
  v_profile RECORD;
  v_new_post RECORD;
  v_scheduled_id UUID;
BEGIN
  v_user_id := auth.uid()::text;
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  IF p_content IS NULL OR length(trim(p_content)) = 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Content required');
  END IF;

  IF NOT public.is_world_member(p_world_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not a member of this world');
  END IF;

  IF p_repost_of IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.posts WHERE id = p_repost_of AND status = 'published'
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Original post not found');
  END IF;

  IF p_scheduled_for IS NOT NULL AND p_scheduled_for > (now() + interval '30 seconds') THEN
    IF p_poll IS NOT NULL AND p_poll <> 'null'::jsonb THEN
      RETURN jsonb_build_object('success', false, 'error', 'Polls cannot be scheduled');
    END IF;

    INSERT INTO public.scheduled_posts (
      world_id, author_id, content, image_url, media,
      is_announcement, is_decree, is_pinned, poll, mentions, hashtags, scheduled_for
    ) VALUES (
      p_world_id, v_user_id, trim(p_content), p_image_url, COALESCE(p_media, '[]'::jsonb),
      COALESCE(p_is_announcement, false), COALESCE(p_is_decree, false),
      COALESCE(p_is_pinned, false), p_poll, COALESCE(p_mentions, '[]'::jsonb),
      COALESCE(p_hashtags, '[]'::jsonb), p_scheduled_for
    )
    RETURNING id INTO v_scheduled_id;

    RETURN jsonb_build_object(
      'success', true,
      'scheduled', true,
      'scheduled_id', v_scheduled_id::text,
      'scheduled_for', p_scheduled_for
    );
  END IF;

  IF p_is_announcement AND NOT public.can_post_announcement(p_world_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Announcement requires council standing');
  END IF;

  IF p_is_decree AND NOT public.can_post_announcement(p_world_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Decree requires council standing');
  END IF;

  IF p_is_pinned AND NOT public.can_post_announcement(p_world_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Pinning requires council standing');
  END IF;

  IF p_poll IS NOT NULL AND p_poll <> 'null'::jsonb THEN
    RETURN jsonb_build_object('success', false, 'error', 'Polls must be created from the poll composer');
  END IF;

  SELECT name, avatar_url, tier INTO v_profile
  FROM public.profiles
  WHERE id = v_user_id;

  v_post_id := gen_random_uuid()::text;

  INSERT INTO public.posts (
    id, world_id, resident_id, resident_name, resident_avatar,
    author_id, author_name, author_avatar,
    content, image_url, media, tier_at_posting,
    is_announcement, is_decree, is_pinned, poll, mentions, hashtags,
    reactions, comments, comment_count, status, repost_of
  ) VALUES (
    v_post_id, p_world_id, v_user_id, v_profile.name, v_profile.avatar_url,
    v_user_id, v_profile.name, v_profile.avatar_url,
    trim(p_content), p_image_url, COALESCE(p_media, '[]'::jsonb), COALESCE(v_profile.tier, 1),
    COALESCE(p_is_announcement, false), COALESCE(p_is_decree, false),
    COALESCE(p_is_pinned, false), p_poll, COALESCE(p_mentions, '[]'::jsonb),
    COALESCE(p_hashtags, '[]'::jsonb),
    '{}'::jsonb, '[]'::jsonb, 0, 'published', p_repost_of
  )
  RETURNING * INTO v_new_post;

  IF p_repost_of IS NOT NULL THEN
    PERFORM public.notify_post_author_social(
      p_repost_of,
      'like',
      'Someone reposted your post',
      'repost-' || p_repost_of || '-' || v_user_id
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'post_id', v_post_id,
    'post', to_jsonb(v_new_post)
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

REVOKE ALL ON FUNCTION public.create_post(
  TEXT, TEXT, TEXT, JSONB, BOOLEAN, BOOLEAN, BOOLEAN, JSONB, JSONB, JSONB, TIMESTAMPTZ, TEXT
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_post(
  TEXT, TEXT, TEXT, JSONB, BOOLEAN, BOOLEAN, BOOLEAN, JSONB, JSONB, JSONB, TIMESTAMPTZ, TEXT
) TO authenticated;
