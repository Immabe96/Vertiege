-- Vertiege — Phase 1: Migration ordering, RLS safety, indexes, constraints, RPCs (20260519)
-- Additive migration: safe to apply on existing projects.
-- Does NOT rename or drop prior migrations.

-- ═══════════════════════════════════════════════════════════════
-- 1. Channel foundation columns (Phase 2 prerequisite)
-- ═══════════════════════════════════════════════════════════════

ALTER TABLE public.channels
  ADD COLUMN IF NOT EXISTS foundation_markdown TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS foundation_version TEXT NOT NULL DEFAULT 'v1';

CREATE INDEX IF NOT EXISTS idx_channels_world_default_name
  ON public.channels(world_id, is_default, name);

-- ═══════════════════════════════════════════════════════════════
-- 2. Fix is_council_or_above to include sovereign check
-- The world_system_complete migration redefined this WITHOUT the sovereign check,
-- breaking policies that rely on sovereigns having council-level access.
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.is_council_or_above(p_world_id TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id TEXT;
  v_sovereign_id TEXT;
  v_rep INT;
BEGIN
  v_user_id := auth.uid()::text;

  -- Sovereign always has council-level access
  SELECT sovereign_id INTO v_sovereign_id FROM public.worlds WHERE id = p_world_id;
  IF v_user_id = v_sovereign_id THEN
    RETURN TRUE;
  END IF;

  -- Council: rep >= 5000
  SELECT rep INTO v_rep FROM public.world_members
    WHERE world_id = p_world_id AND resident_id = v_user_id;
  RETURN COALESCE(v_rep, 0) >= 5000;
END;
$$;

-- ═══════════════════════════════════════════════════════════════
-- 3. RLS policies for tables created after the base schema
-- ═══════════════════════════════════════════════════════════════

-- world_announcements (created in world_system_complete)
ALTER TABLE public.world_announcements ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "announcements_read" ON public.world_announcements;
CREATE POLICY "announcements_read" ON public.world_announcements
  FOR SELECT USING (public.is_world_member(world_id));
DROP POLICY IF EXISTS "announcements_insert" ON public.world_announcements;
CREATE POLICY "announcements_insert" ON public.world_announcements
  FOR INSERT WITH CHECK (public.is_sovereign_or_council(world_id));
DROP POLICY IF EXISTS "announcements_update" ON public.world_announcements;
CREATE POLICY "announcements_update" ON public.world_announcements
  FOR UPDATE USING (public.is_sovereign_or_council(world_id));
DROP POLICY IF EXISTS "announcements_delete" ON public.world_announcements;
CREATE POLICY "announcements_delete" ON public.world_announcements
  FOR DELETE USING (public.is_sovereign_or_council(world_id));

-- world_listings
ALTER TABLE public.world_listings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "listings_read" ON public.world_listings;
CREATE POLICY "listings_read" ON public.world_listings
  FOR SELECT USING (public.is_world_member(world_id) OR status = 'active');
DROP POLICY IF EXISTS "listings_insert" ON public.world_listings;
CREATE POLICY "listings_insert" ON public.world_listings
  FOR INSERT WITH CHECK (seller_id = auth.uid()::text);
DROP POLICY IF EXISTS "listings_update" ON public.world_listings;
CREATE POLICY "listings_update" ON public.world_listings
  FOR UPDATE USING (seller_id = auth.uid()::text);
DROP POLICY IF EXISTS "listings_delete" ON public.world_listings;
CREATE POLICY "listings_delete" ON public.world_listings
  FOR DELETE USING (seller_id = auth.uid()::text);

-- world_currency
ALTER TABLE public.world_currency ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "currency_read" ON public.world_currency;
CREATE POLICY "currency_read" ON public.world_currency
  FOR SELECT USING (resident_id = auth.uid()::text OR public.is_world_member(world_id));

-- world_treasury
ALTER TABLE public.world_treasury ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "treasury_read" ON public.world_treasury;
CREATE POLICY "treasury_read" ON public.world_treasury
  FOR SELECT USING (public.is_world_member(world_id));

-- treasury_transactions
ALTER TABLE public.treasury_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "treasury_tx_read" ON public.treasury_transactions;
CREATE POLICY "treasury_tx_read" ON public.treasury_transactions
  FOR SELECT USING (public.is_world_member(world_id));
DROP POLICY IF EXISTS "treasury_tx_insert" ON public.treasury_transactions;
CREATE POLICY "treasury_tx_insert" ON public.treasury_transactions
  FOR INSERT WITH CHECK (public.is_world_member(world_id));

-- world_polls
ALTER TABLE public.world_polls ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "polls_read" ON public.world_polls;
CREATE POLICY "polls_read" ON public.world_polls
  FOR SELECT USING (public.is_world_member(world_id));
DROP POLICY IF EXISTS "polls_insert" ON public.world_polls;
CREATE POLICY "polls_insert" ON public.world_polls
  FOR INSERT WITH CHECK (public.is_council_or_above(world_id));
DROP POLICY IF EXISTS "polls_update" ON public.world_polls;
CREATE POLICY "polls_update" ON public.world_polls
  FOR UPDATE USING (public.is_council_or_above(world_id));

-- world_milestones
ALTER TABLE public.world_milestones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "milestones_read" ON public.world_milestones;
CREATE POLICY "milestones_read" ON public.world_milestones
  FOR SELECT USING (public.is_world_member(world_id));

-- world_timeline
ALTER TABLE public.world_timeline ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "timeline_read" ON public.world_timeline;
CREATE POLICY "timeline_read" ON public.world_timeline
  FOR SELECT USING (public.is_world_member(world_id));

-- world_challenges
ALTER TABLE public.world_challenges ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "challenges_read" ON public.world_challenges;
CREATE POLICY "challenges_read" ON public.world_challenges
  FOR SELECT USING (public.is_world_member(world_id));
DROP POLICY IF EXISTS "challenges_insert" ON public.world_challenges;
CREATE POLICY "challenges_insert" ON public.world_challenges
  FOR INSERT WITH CHECK (public.is_sovereign_or_council(world_id));
DROP POLICY IF EXISTS "challenges_update" ON public.world_challenges;
CREATE POLICY "challenges_update" ON public.world_challenges
  FOR UPDATE USING (public.is_sovereign_or_council(world_id));

-- challenge_progress
ALTER TABLE public.challenge_progress ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "challenge_progress_read" ON public.challenge_progress;
CREATE POLICY "challenge_progress_read" ON public.challenge_progress
  FOR SELECT USING (
    resident_id = auth.uid()::text
    OR public.is_world_member((SELECT world_id FROM public.world_challenges WHERE id = challenge_id))
  );
DROP POLICY IF EXISTS "challenge_progress_insert" ON public.challenge_progress;
CREATE POLICY "challenge_progress_insert" ON public.challenge_progress
  FOR INSERT WITH CHECK (resident_id = auth.uid()::text);
DROP POLICY IF EXISTS "challenge_progress_update" ON public.challenge_progress;
CREATE POLICY "challenge_progress_update" ON public.challenge_progress
  FOR UPDATE USING (resident_id = auth.uid()::text);

-- world_templates
ALTER TABLE public.world_templates ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "templates_read" ON public.world_templates;
CREATE POLICY "templates_read" ON public.world_templates
  FOR SELECT USING (is_public OR creator_id = auth.uid()::text);
DROP POLICY IF EXISTS "templates_insert" ON public.world_templates;
CREATE POLICY "templates_insert" ON public.world_templates
  FOR INSERT WITH CHECK (creator_id = auth.uid()::text);
DROP POLICY IF EXISTS "templates_update" ON public.world_templates;
CREATE POLICY "templates_update" ON public.world_templates
  FOR UPDATE USING (creator_id = auth.uid()::text);
DROP POLICY IF EXISTS "templates_delete" ON public.world_templates;
CREATE POLICY "templates_delete" ON public.world_templates
  FOR DELETE USING (creator_id = auth.uid()::text);

-- world_analytics
ALTER TABLE public.world_analytics ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "analytics_read" ON public.world_analytics;
CREATE POLICY "analytics_read" ON public.world_analytics
  FOR SELECT USING (public.is_sovereign_or_council(world_id));

-- world_rivalries
ALTER TABLE public.world_rivalries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "rivalries_read" ON public.world_rivalries;
CREATE POLICY "rivalries_read" ON public.world_rivalries
  FOR SELECT USING (public.is_world_member(world_1_id) OR public.is_world_member(world_2_id));
DROP POLICY IF EXISTS "rivalries_insert" ON public.world_rivalries;
CREATE POLICY "rivalries_insert" ON public.world_rivalries
  FOR INSERT WITH CHECK (
    public.is_sovereign_or_council(world_1_id) AND public.is_sovereign_or_council(world_2_id)
  );

-- academy_courses
ALTER TABLE public.academy_courses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "courses_read" ON public.academy_courses;
CREATE POLICY "courses_read" ON public.academy_courses
  FOR SELECT USING (public.is_world_member(world_id));
DROP POLICY IF EXISTS "courses_insert" ON public.academy_courses;
CREATE POLICY "courses_insert" ON public.academy_courses
  FOR INSERT WITH CHECK (public.is_world_member(world_id));
DROP POLICY IF EXISTS "courses_update" ON public.academy_courses;
CREATE POLICY "courses_update" ON public.academy_courses
  FOR UPDATE USING (instructor_id = auth.uid()::text OR public.is_sovereign_or_council(world_id));

-- academy_enrollments
ALTER TABLE public.academy_enrollments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "enrollments_read" ON public.academy_enrollments;
CREATE POLICY "enrollments_read" ON public.academy_enrollments
  FOR SELECT USING (
    student_id = auth.uid()::text
    OR public.is_world_member((SELECT world_id FROM public.academy_courses WHERE id = course_id))
  );
DROP POLICY IF EXISTS "enrollments_insert" ON public.academy_enrollments;
CREATE POLICY "enrollments_insert" ON public.academy_enrollments
  FOR INSERT WITH CHECK (student_id = auth.uid()::text);

-- academy_assignments
ALTER TABLE public.academy_assignments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "assignments_read" ON public.academy_assignments;
CREATE POLICY "assignments_read" ON public.academy_assignments
  FOR SELECT USING (
    public.is_world_member((SELECT world_id FROM public.academy_courses WHERE id = course_id))
  );

-- academy_submissions
ALTER TABLE public.academy_submissions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "submissions_read" ON public.academy_submissions;
CREATE POLICY "submissions_read" ON public.academy_submissions
  FOR SELECT USING (
    student_id = auth.uid()::text
    OR public.is_world_member((
      SELECT world_id FROM public.academy_courses
      WHERE id = (SELECT course_id FROM public.academy_assignments WHERE id = assignment_id)
    ))
  );
DROP POLICY IF EXISTS "submissions_insert" ON public.academy_submissions;
CREATE POLICY "submissions_insert" ON public.academy_submissions
  FOR INSERT WITH CHECK (student_id = auth.uid()::text);
DROP POLICY IF EXISTS "submissions_update" ON public.academy_submissions;
CREATE POLICY "submissions_update" ON public.academy_submissions
  FOR UPDATE USING (
    student_id = auth.uid()::text
    OR public.is_world_member((
      SELECT world_id FROM public.academy_courses
      WHERE id = (SELECT course_id FROM public.academy_assignments WHERE id = assignment_id)
    ))
  );

-- archive_documents
ALTER TABLE public.archive_documents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "documents_read" ON public.archive_documents;
CREATE POLICY "documents_read" ON public.archive_documents
  FOR SELECT USING (public.is_world_member(world_id) OR is_published);
DROP POLICY IF EXISTS "documents_insert" ON public.archive_documents;
CREATE POLICY "documents_insert" ON public.archive_documents
  FOR INSERT WITH CHECK (public.is_world_member(world_id));
DROP POLICY IF EXISTS "documents_update" ON public.archive_documents;
CREATE POLICY "documents_update" ON public.archive_documents
  FOR UPDATE USING (author_id = auth.uid()::text OR public.is_sovereign_or_council(world_id));
DROP POLICY IF EXISTS "documents_delete" ON public.archive_documents;
CREATE POLICY "documents_delete" ON public.archive_documents
  FOR DELETE USING (author_id = auth.uid()::text OR public.is_sovereign_or_council(world_id));

-- archive_document_versions
ALTER TABLE public.archive_document_versions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "doc_versions_read" ON public.archive_document_versions;
CREATE POLICY "doc_versions_read" ON public.archive_document_versions
  FOR SELECT USING (
    public.is_world_member((SELECT world_id FROM public.archive_documents WHERE id = document_id))
  );

-- archive_curators
ALTER TABLE public.archive_curators ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "curators_read" ON public.archive_curators;
CREATE POLICY "curators_read" ON public.archive_curators
  FOR SELECT USING (public.is_world_member(world_id));

-- activity_xp_log
ALTER TABLE public.activity_xp_log ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "activity_xp_self_read" ON public.activity_xp_log;
CREATE POLICY "activity_xp_self_read" ON public.activity_xp_log
  FOR SELECT USING (user_id = auth.uid()::text);

-- tier_perks
ALTER TABLE public.tier_perks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tier_perks_public_read" ON public.tier_perks;
CREATE POLICY "tier_perks_public_read" ON public.tier_perks
  FOR SELECT USING (true);

-- league_seasons (already has RLS from phase4 migration, ensure policy exists)
ALTER TABLE public.league_seasons ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "league_seasons_public_read" ON public.league_seasons;
CREATE POLICY "league_seasons_public_read" ON public.league_seasons
  FOR SELECT USING (true);

-- league_participants (already has RLS, ensure policies)
ALTER TABLE public.league_participants ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "league_participants_read" ON public.league_participants;
CREATE POLICY "league_participants_read" ON public.league_participants
  FOR SELECT USING (true);
DROP POLICY IF EXISTS "league_participants_self_update" ON public.league_participants;
CREATE POLICY "league_participants_self_update" ON public.league_participants
  FOR UPDATE USING (user_id = auth.uid()::text);

-- bookmarks (already has RLS from forui_hybrid migration, ensure policies)
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "bookmarks_read_own" ON public.bookmarks;
CREATE POLICY "bookmarks_read_own" ON public.bookmarks
  FOR SELECT USING (COALESCE(user_id, resident_id) = auth.uid()::text);
DROP POLICY IF EXISTS "bookmarks_insert_own" ON public.bookmarks;
CREATE POLICY "bookmarks_insert_own" ON public.bookmarks
  FOR INSERT WITH CHECK (COALESCE(user_id, resident_id) = auth.uid()::text);
DROP POLICY IF EXISTS "bookmarks_delete_own" ON public.bookmarks;
CREATE POLICY "bookmarks_delete_own" ON public.bookmarks
  FOR DELETE USING (COALESCE(user_id, resident_id) = auth.uid()::text);

-- device_tokens (already has RLS from forui_hybrid migration)
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "device_tokens_read_own" ON public.device_tokens;
CREATE POLICY "device_tokens_read_own" ON public.device_tokens
  FOR SELECT USING (resident_id = auth.uid()::text);
DROP POLICY IF EXISTS "device_tokens_upsert_own" ON public.device_tokens;
CREATE POLICY "device_tokens_upsert_own" ON public.device_tokens
  FOR INSERT WITH CHECK (resident_id = auth.uid()::text);
DROP POLICY IF EXISTS "device_tokens_update_own" ON public.device_tokens;
CREATE POLICY "device_tokens_update_own" ON public.device_tokens
  FOR UPDATE USING (resident_id = auth.uid()::text) WITH CHECK (resident_id = auth.uid()::text);
DROP POLICY IF EXISTS "device_tokens_delete_own" ON public.device_tokens;
CREATE POLICY "device_tokens_delete_own" ON public.device_tokens
  FOR DELETE USING (resident_id = auth.uid()::text);

-- ═══════════════════════════════════════════════════════════════
-- 4. Additional indexes for common query patterns
-- ═══════════════════════════════════════════════════════════════

-- Channels: lookup by world + default flag
CREATE INDEX IF NOT EXISTS idx_channels_world_is_default
  ON public.channels(world_id, is_default);

-- Bookmarks: already has unique index, add composite for user queries
CREATE INDEX IF NOT EXISTS idx_bookmarks_user_created
  ON public.bookmarks(COALESCE(user_id, resident_id), created_at DESC);

-- World members: composite for feed membership checks
CREATE INDEX IF NOT EXISTS idx_world_members_world_resident
  ON public.world_members(world_id, resident_id);

-- Posts: composite for world feed with pinned posts first
CREATE INDEX IF NOT EXISTS idx_posts_world_pinned_created
  ON public.posts(world_id, is_pinned DESC, created_at DESC)
  WHERE deleted_at IS NULL;

-- Channel messages: composite for channel feed
CREATE INDEX IF NOT EXISTS idx_channel_messages_channel_thread_created
  ON public.channel_messages(channel_id, is_thread_starter DESC, created_at DESC);

-- Notifications: composite for unread ordering
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_read_created
  ON public.notifications(recipient_id, read, created_at DESC);

-- World polls: index for active polls
CREATE INDEX IF NOT EXISTS idx_polls_world_active
  ON public.world_polls(world_id, is_closed, created_at DESC);

-- World challenges: index for active challenges
CREATE INDEX IF NOT EXISTS idx_challenges_world_active
  ON public.world_challenges(world_id, is_active, expires_at DESC);

-- Device tokens: already has index on resident_id

-- Treasury: index for world treasury lookup
CREATE INDEX IF NOT EXISTS idx_treasury_world
  ON public.world_treasury(world_id);

-- World currency: composite for user balance lookup
CREATE INDEX IF NOT EXISTS idx_currency_world_resident
  ON public.world_currency(world_id, resident_id);

-- ═══════════════════════════════════════════════════════════════
-- 5. RPC: Join world (atomic)
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.join_world(
  p_world_id TEXT,
  p_resident_name TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id TEXT;
  v_world RECORD;
  v_result JSONB;
BEGIN
  v_user_id := auth.uid()::text;

  -- Check world exists
  SELECT * INTO v_world FROM public.worlds WHERE id = p_world_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'World not found');
  END IF;

  -- Check not banned
  IF public.is_banned_from_world(p_world_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Banned from this world');
  END IF;

  -- Check already a member
  IF public.is_world_member(p_world_id) THEN
    RETURN jsonb_build_object('success', true, 'message', 'Already a member');
  END IF;

  -- Insert membership
  INSERT INTO public.world_members (world_id, resident_id, resident_name)
    VALUES (p_world_id, v_user_id, p_resident_name);

  -- Increment member count
  UPDATE public.worlds SET member_count = member_count + 1 WHERE id = p_world_id;

  -- Add to profile's joined_world_ids array
  UPDATE public.profiles
    SET joined_world_ids = array_append(
      COALESCE(joined_world_ids, '{}'),
      p_world_id
    )
    WHERE id = v_user_id;

  RETURN jsonb_build_object('success', true, 'world_id', p_world_id);
END;
$$;

GRANT EXECUTE ON FUNCTION public.join_world(TEXT, TEXT) TO authenticated;

-- ═══════════════════════════════════════════════════════════════
-- 6. RPC: Leave world (atomic)
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.leave_world(
  p_world_id TEXT
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

  -- Cannot leave if sovereign
  IF EXISTS (SELECT 1 FROM public.worlds WHERE id = p_world_id AND sovereign_id = v_user_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Sovereign cannot leave their world');
  END IF;

  -- Remove membership
  DELETE FROM public.world_members
    WHERE world_id = p_world_id AND resident_id = v_user_id;

  -- Decrement member count
  UPDATE public.worlds SET member_count = GREATEST(member_count - 1, 0) WHERE id = p_world_id;

  -- Remove from profile's joined_world_ids array
  UPDATE public.profiles
    SET joined_world_ids = array_remove(
      COALESCE(joined_world_ids, '{}'),
      p_world_id
    )
    WHERE id = v_user_id;

  RETURN jsonb_build_object('success', true, 'world_id', p_world_id);
END;
$$;

GRANT EXECUTE ON FUNCTION public.leave_world(TEXT) TO authenticated;

-- ═══════════════════════════════════════════════════════════════
-- 7. RPC: Bookmark post (atomic upsert)
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.bookmark_post(
  p_post_id TEXT
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

  INSERT INTO public.bookmarks (user_id, resident_id, post_id)
    VALUES (v_user_id, v_user_id, p_post_id)
    ON CONFLICT DO NOTHING;

  RETURN jsonb_build_object('success', true);
END;
$$;

GRANT EXECUTE ON FUNCTION public.bookmark_post(TEXT) TO authenticated;

-- ═══════════════════════════════════════════════════════════════
-- 8. RPC: Unbookmark post (atomic delete)
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.unbookmark_post(
  p_post_id TEXT
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

  DELETE FROM public.bookmarks
    WHERE post_id = p_post_id
      AND COALESCE(user_id, resident_id) = v_user_id;

  RETURN jsonb_build_object('success', true);
END;
$$;

GRANT EXECUTE ON FUNCTION public.unbookmark_post(TEXT) TO authenticated;

-- ═══════════════════════════════════════════════════════════════
-- 9. RPC: Vote on poll (improved version with user tracking)
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.vote_on_poll_v2(
  p_poll_id UUID,
  p_option_index INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_poll RECORD;
  v_results JSONB;
  v_option_count INT;
  v_user_id TEXT;
  v_voters JSONB;
  v_new_results JSONB;
BEGIN
  v_user_id := auth.uid()::text;

  SELECT * INTO v_poll FROM public.world_polls WHERE id = p_poll_id AND is_closed = FALSE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Poll not found or closed');
  END IF;

  -- Check user is world member
  IF NOT public.is_world_member(v_poll.world_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not a member of this world');
  END IF;

  v_results := COALESCE(v_poll.results, '{}'::jsonb);
  v_option_count := jsonb_array_length(v_poll.options);

  IF p_option_index < 0 OR p_option_index >= v_option_count THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid option index');
  END IF;

  -- Track voters per option to prevent double-voting
  -- results format: {"0": {"count": 5, "voters": ["user1", "user2"]}, "1": {...}}
  v_voters := v_results->>p_option_index::text;
  IF v_voters IS NULL OR v_voters = 'null' THEN
    -- First vote on this option
    v_new_results := jsonb_set(v_results, ARRAY[p_option_index::text],
      jsonb_build_object('count', 1, 'voters', jsonb_build_array(v_user_id)));
  ELSE
    -- Check if already voted on this option
    IF v_voters::jsonb ? 'voters' AND (v_voters::jsonb->'voters') ? v_user_id THEN
      RETURN jsonb_build_object('success', false, 'error', 'Already voted on this option');
    END IF;

    -- Increment count and add voter
    v_new_results := jsonb_set(v_results, ARRAY[p_option_index::text],
      jsonb_build_object(
        'count', COALESCE((v_voters::jsonb->>'count')::int, 0) + 1,
        'voters', COALESCE(v_voters::jsonb->'voters', '[]'::jsonb) || to_jsonb(v_user_id)
      ));
  END IF;

  UPDATE public.world_polls SET results = v_new_results WHERE id = p_poll_id;

  RETURN jsonb_build_object('success', true, 'results', v_new_results);
END;
$$;

GRANT EXECUTE ON FUNCTION public.vote_on_poll_v2(UUID, INT) TO authenticated;

-- ═══════════════════════════════════════════════════════════════
-- 10. RPC: Create post with media references (atomic)
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.create_post(
  p_world_id TEXT,
  p_content TEXT,
  p_image_url TEXT DEFAULT NULL,
  p_media JSONB DEFAULT '[]',
  p_is_announcement BOOLEAN DEFAULT false,
  p_is_decree BOOLEAN DEFAULT false,
  p_poll JSONB DEFAULT NULL,
  p_mentions JSONB DEFAULT '[]',
  p_hashtags JSONB DEFAULT '[]'
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
BEGIN
  v_user_id := auth.uid()::text;

  -- Check world membership
  IF NOT public.is_world_member(p_world_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not a member of this world');
  END IF;

  -- Get profile data
  SELECT name, avatar_url, tier INTO v_profile FROM public.profiles WHERE id = v_user_id;

  -- Generate post ID
  v_post_id := gen_random_uuid()::text;

  INSERT INTO public.posts (
    id, world_id, resident_id, resident_name, resident_avatar,
    content, image_url, media, tier_at_posting,
    is_announcement, is_decree, poll, mentions, hashtags,
    reactions, comments, comment_count
  ) VALUES (
    v_post_id, p_world_id, v_user_id, v_profile.name, v_profile.avatar_url,
    p_content, p_image_url, p_media, v_profile.tier,
    p_is_announcement, p_is_decree, p_poll, p_mentions, p_hashtags,
    '{}'::jsonb, '[]'::jsonb, 0
  ) RETURNING * INTO v_new_post;

  RETURN jsonb_build_object(
    'success', true,
    'post_id', v_post_id,
    'post', jsonb_build_object(
      'id', v_new_post.id,
      'world_id', v_new_post.world_id,
      'resident_id', v_new_post.resident_id,
      'resident_name', v_new_post.resident_name,
      'content', v_new_post.content,
      'created_at', v_new_post.created_at
    )
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_post(TEXT, TEXT, TEXT, JSONB, BOOLEAN, BOOLEAN, JSONB, JSONB, JSONB) TO authenticated;

-- ═══════════════════════════════════════════════════════════════
-- 11. RPC: Update comment count (atomic)
-- ═══════════════════════════════════════════════════════════════

-- increment_comment_count already exists, ensure it's correct
CREATE OR REPLACE FUNCTION public.increment_comment_count(p_post_id TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  UPDATE public.posts SET comment_count = comment_count + 1 WHERE id = p_post_id;
END;
$$;

-- ═══════════════════════════════════════════════════════════════
-- 12. Seed default channel foundation markdown for existing channels
-- ═══════════════════════════════════════════════════════════════

-- This backfill sets foundation_markdown for existing default channels
-- that have empty foundation_markdown. It uses the world slug to determine content.
-- The actual markdown content is set by the app's world_foundations.dart utility.
-- Here we set a placeholder that the app will recognize and replace on next load.

UPDATE public.channels
SET foundation_markdown = '__NEEDS_BACKFILL__',
    foundation_version = 'v1'
WHERE is_default = true
  AND (foundation_markdown IS NULL OR foundation_markdown = '' OR foundation_markdown = '__NEEDS_BACKFILL__')
  AND name IN ('info', 'rules', 'roles');
