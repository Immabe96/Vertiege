-- Wave 21: scheduled posts, notification preferences, feed cursor RPC, indexes.

-- ─── Scheduled posts ───
CREATE TABLE IF NOT EXISTS public.scheduled_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  author_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  image_url TEXT,
  media JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_announcement BOOLEAN NOT NULL DEFAULT false,
  is_decree BOOLEAN NOT NULL DEFAULT false,
  is_pinned BOOLEAN NOT NULL DEFAULT false,
  poll JSONB,
  mentions JSONB NOT NULL DEFAULT '[]'::jsonb,
  hashtags JSONB NOT NULL DEFAULT '[]'::jsonb,
  scheduled_for TIMESTAMPTZ NOT NULL,
  published_at TIMESTAMPTZ,
  post_id TEXT REFERENCES public.posts(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT scheduled_posts_future_at_create CHECK (scheduled_for > created_at)
);

CREATE INDEX IF NOT EXISTS idx_scheduled_posts_due
  ON public.scheduled_posts (scheduled_for)
  WHERE published_at IS NULL;

ALTER TABLE public.scheduled_posts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS scheduled_posts_author ON public.scheduled_posts;
CREATE POLICY scheduled_posts_author ON public.scheduled_posts
  FOR ALL
  USING (author_id = auth.uid()::text)
  WITH CHECK (author_id = auth.uid()::text);

CREATE OR REPLACE FUNCTION public.publish_due_scheduled_posts()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_row RECORD;
  v_profile RECORD;
  v_post_id TEXT;
  v_count INT := 0;
BEGIN
  FOR v_row IN
    SELECT *
    FROM public.scheduled_posts
    WHERE published_at IS NULL
      AND scheduled_for <= now()
    ORDER BY scheduled_for ASC
    LIMIT 50
    FOR UPDATE SKIP LOCKED
  LOOP
    SELECT name, avatar_url, tier INTO v_profile
    FROM public.profiles
    WHERE id = v_row.author_id;

    IF NOT FOUND THEN
      UPDATE public.scheduled_posts
      SET published_at = now()
      WHERE id = v_row.id;
      CONTINUE;
    END IF;

    IF NOT public.is_world_member(v_row.world_id) THEN
      UPDATE public.scheduled_posts
      SET published_at = now()
      WHERE id = v_row.id;
      CONTINUE;
    END IF;

    v_post_id := gen_random_uuid()::text;

    INSERT INTO public.posts (
      id, world_id, resident_id, resident_name, resident_avatar,
      author_id, author_name, author_avatar,
      content, image_url, media, tier_at_posting,
      is_announcement, is_decree, is_pinned, poll, mentions, hashtags,
      reactions, comments, comment_count, status
    ) VALUES (
      v_post_id, v_row.world_id, v_row.author_id, v_profile.name, v_profile.avatar_url,
      v_row.author_id, v_profile.name, v_profile.avatar_url,
      trim(v_row.content), v_row.image_url, COALESCE(v_row.media, '[]'::jsonb),
      COALESCE(v_profile.tier, 1),
      v_row.is_announcement, v_row.is_decree, v_row.is_pinned,
      v_row.poll, COALESCE(v_row.mentions, '[]'::jsonb),
      COALESCE(v_row.hashtags, '[]'::jsonb),
      '{}'::jsonb, '[]'::jsonb, 0, 'published'
    );

    UPDATE public.scheduled_posts
    SET published_at = now(), post_id = v_post_id
    WHERE id = v_row.id;

    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;

REVOKE ALL ON FUNCTION public.publish_due_scheduled_posts() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.publish_due_scheduled_posts() TO service_role;

-- ─── Notification preferences ───
CREATE TABLE IF NOT EXISTS public.notification_preferences (
  resident_id TEXT PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  likes_enabled BOOLEAN NOT NULL DEFAULT true,
  comments_enabled BOOLEAN NOT NULL DEFAULT true,
  world_invites_enabled BOOLEAN NOT NULL DEFAULT true,
  tier_upgrades_enabled BOOLEAN NOT NULL DEFAULT true,
  push_enabled BOOLEAN NOT NULL DEFAULT true,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS notification_preferences_self ON public.notification_preferences;
CREATE POLICY notification_preferences_self ON public.notification_preferences
  FOR ALL
  USING (resident_id = auth.uid()::text)
  WITH CHECK (resident_id = auth.uid()::text);

CREATE OR REPLACE FUNCTION public.get_notification_preferences()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id TEXT;
  v_row public.notification_preferences%ROWTYPE;
BEGIN
  v_user_id := auth.uid()::text;
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  SELECT * INTO v_row
  FROM public.notification_preferences
  WHERE resident_id = v_user_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', true,
      'preferences', jsonb_build_object(
        'likes_enabled', true,
        'comments_enabled', true,
        'world_invites_enabled', true,
        'tier_upgrades_enabled', true,
        'push_enabled', true
      )
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'preferences', jsonb_build_object(
      'likes_enabled', v_row.likes_enabled,
      'comments_enabled', v_row.comments_enabled,
      'world_invites_enabled', v_row.world_invites_enabled,
      'tier_upgrades_enabled', v_row.tier_upgrades_enabled,
      'push_enabled', v_row.push_enabled
    )
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.upsert_notification_preferences(
  p_likes_enabled BOOLEAN DEFAULT NULL,
  p_comments_enabled BOOLEAN DEFAULT NULL,
  p_world_invites_enabled BOOLEAN DEFAULT NULL,
  p_tier_upgrades_enabled BOOLEAN DEFAULT NULL,
  p_push_enabled BOOLEAN DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id TEXT;
BEGIN
  v_user_id := auth.uid()::text;
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  INSERT INTO public.notification_preferences (
    resident_id,
    likes_enabled,
    comments_enabled,
    world_invites_enabled,
    tier_upgrades_enabled,
    push_enabled,
    updated_at
  ) VALUES (
    v_user_id,
    COALESCE(p_likes_enabled, true),
    COALESCE(p_comments_enabled, true),
    COALESCE(p_world_invites_enabled, true),
    COALESCE(p_tier_upgrades_enabled, true),
    COALESCE(p_push_enabled, true),
    now()
  )
  ON CONFLICT (resident_id) DO UPDATE SET
    likes_enabled = COALESCE(p_likes_enabled, notification_preferences.likes_enabled),
    comments_enabled = COALESCE(p_comments_enabled, notification_preferences.comments_enabled),
    world_invites_enabled = COALESCE(
      p_world_invites_enabled, notification_preferences.world_invites_enabled
    ),
    tier_upgrades_enabled = COALESCE(
      p_tier_upgrades_enabled, notification_preferences.tier_upgrades_enabled
    ),
    push_enabled = COALESCE(p_push_enabled, notification_preferences.push_enabled),
    updated_at = now();

  RETURN public.get_notification_preferences();
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_notification_preferences() TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_notification_preferences(
  BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN
) TO authenticated;

-- ─── Keyset feed pagination ───
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

GRANT EXECUTE ON FUNCTION public.list_posts_cursor(TEXT, TIMESTAMPTZ, INT) TO authenticated;

-- ─── create_post: queue future schedules ───
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
  p_scheduled_for TIMESTAMPTZ DEFAULT NULL
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
    reactions, comments, comment_count, status
  ) VALUES (
    v_post_id, p_world_id, v_user_id, v_profile.name, v_profile.avatar_url,
    v_user_id, v_profile.name, v_profile.avatar_url,
    trim(p_content), p_image_url, COALESCE(p_media, '[]'::jsonb), COALESCE(v_profile.tier, 1),
    COALESCE(p_is_announcement, false), COALESCE(p_is_decree, false),
    COALESCE(p_is_pinned, false), p_poll, COALESCE(p_mentions, '[]'::jsonb),
    COALESCE(p_hashtags, '[]'::jsonb),
    '{}'::jsonb, '[]'::jsonb, 0, 'published'
  )
  RETURNING * INTO v_new_post;

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

-- ─── Performance indexes (advisor-aligned) ───
CREATE INDEX IF NOT EXISTS idx_world_members_resident_world
  ON public.world_members (resident_id, world_id);

CREATE INDEX IF NOT EXISTS idx_posts_world_status_created
  ON public.posts (world_id, status, created_at DESC);

-- pg_cron publish worker (no-op if extension unavailable)
DO $cron$
BEGIN
  CREATE EXTENSION IF NOT EXISTS pg_cron;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'pg_cron not available: schedule publish_due_scheduled_posts on staging';
END;
$cron$;

DO $schedule$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.schedule(
      'vertiege-publish-scheduled-posts',
      '* * * * *',
      $$SELECT public.publish_due_scheduled_posts()$$
    );
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'pg_cron schedule skipped: %', SQLERRM;
END;
$schedule$;
