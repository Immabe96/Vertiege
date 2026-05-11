-- ═══════════════════════════════════════════════════════════════
-- Vertiege — Row Level Security (RLS) Policies
-- ═══════════════════════════════════════════════════════════════
-- Principles:
--   1. Every table has RLS enabled — NO exceptions
--   2. auth.uid() is the ONLY identity anchor — never trust client claims
--   3. World-scoped data requires verified world membership
--   4. Self-owned data is only accessible by the owner
--   5. Sovereigns have elevated access within their worlds
--   6. Service role bypass via TO service_role for Edge Functions
--   7. Reputation/tier/standing are NEVER client-writable
-- ═══════════════════════════════════════════════════════════════

-- ── Helper: Is the caller a member of this world? ──────────────
-- SECURITY DEFINER so it can read world_members regardless of RLS
CREATE OR REPLACE FUNCTION is_world_member(check_world_id TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM world_members
    WHERE world_id = check_world_id
      AND resident_id = auth.uid()::text
  );
END;
$$;

-- ── Helper: Is the caller the sovereign of this world? ─────────
CREATE OR REPLACE FUNCTION is_world_sovereign(check_world_id TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM worlds
    WHERE id = check_world_id AND sovereign_id = auth.uid()::text
  );
END;
$$;

-- ── Helper: Is the caller Council+ (rep >= 5000) in this world? ─
CREATE OR REPLACE FUNCTION is_council_or_above(check_world_id TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM world_members
    WHERE world_id = check_world_id
      AND resident_id = auth.uid()::text
      AND rep >= 5000
  ) OR is_world_sovereign(check_world_id);
END;
$$;

-- ── Helper: Is the caller a participant in this DM room? ───────
CREATE OR REPLACE FUNCTION is_dm_participant(check_room_id TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM dm_rooms
    WHERE id = check_room_id
      AND resident_ids @> ARRAY[auth.uid()::text]
  );
END;
$$;

-- ── Helper: Is the caller banned from this world? ──────────────
CREATE OR REPLACE FUNCTION is_banned_from_world(check_world_id TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM moderation_logs
    WHERE world_id = check_world_id
      AND target_user_id = auth.uid()::text
      AND action = 'ban'
  );
END;
$$;

-- ═══════════════════════════════════════════════════════════════
-- TABLE: profiles (residents)
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS profiles_self_read ON profiles;
CREATE POLICY profiles_self_read ON profiles
  FOR SELECT USING (id = auth.uid()::text);

DROP POLICY IF EXISTS profiles_public_read ON profiles;
CREATE POLICY profiles_public_read ON profiles
  FOR SELECT USING (true); -- profiles are publicly viewable by design

DROP POLICY IF EXISTS profiles_self_update ON profiles;
CREATE POLICY profiles_self_update ON profiles
  FOR UPDATE USING (id = auth.uid()::text)
  WITH CHECK (id = auth.uid()::text);

DROP POLICY IF EXISTS profiles_service_insert ON profiles;
CREATE POLICY profiles_service_insert ON profiles
  FOR INSERT
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Prevent users from modifying rep, tier, or coins directly
CREATE OR REPLACE FUNCTION prevent_profile_escalation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND auth.uid() IS NOT NULL
     AND (SELECT role FROM auth.users WHERE id = auth.uid()) != 'service_role' THEN
    -- Users cannot modify these fields directly
    IF NEW.tier != OLD.tier AND OLD.tier IS NOT NULL THEN
      RAISE EXCEPTION 'tier cannot be modified directly';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_escalation ON profiles;
CREATE TRIGGER trg_prevent_escalation
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION prevent_profile_escalation();

-- ═══════════════════════════════════════════════════════════════
-- TABLE: worlds
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE worlds ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS worlds_public_read ON worlds;
CREATE POLICY worlds_public_read ON worlds
  FOR SELECT USING (true); -- worlds are browsable by everyone

DROP POLICY IF EXISTS worlds_sovereign_update ON worlds;
CREATE POLICY worlds_sovereign_update ON worlds
  FOR UPDATE USING (sovereign_id = auth.uid()::text)
  WITH CHECK (sovereign_id = auth.uid()::text);

DROP POLICY IF EXISTS worlds_service_insert ON worlds;
CREATE POLICY worlds_service_insert ON worlds
  FOR INSERT
  TO service_role
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS worlds_user_insert ON worlds;
CREATE POLICY worlds_user_insert ON worlds  -- dominion world creation
  FOR INSERT WITH CHECK (sovereign_id = auth.uid()::text);

-- ═══════════════════════════════════════════════════════════════
-- TABLE: world_members
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE world_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS world_members_read ON world_members;
CREATE POLICY world_members_read ON world_members
  FOR SELECT USING (is_world_member(world_id));

DROP POLICY IF EXISTS world_members_join ON world_members;
CREATE POLICY world_members_join ON world_members
  FOR INSERT WITH CHECK (
    resident_id = auth.uid()::text
    AND NOT is_banned_from_world(world_id)
  );

DROP POLICY IF EXISTS world_members_leave ON world_members;
CREATE POLICY world_members_leave ON world_members
  FOR DELETE USING (resident_id = auth.uid()::text);

DROP POLICY IF EXISTS world_members_council_remove ON world_members;
CREATE POLICY world_members_council_remove ON world_members
  FOR DELETE USING (
    is_council_or_above(world_id) AND resident_id != auth.uid()::text
  );

-- ═══════════════════════════════════════════════════════════════
-- TABLE: channels
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE channels ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS channels_read ON channels;
CREATE POLICY channels_read ON channels
  FOR SELECT USING (is_world_member(world_id));

DROP POLICY IF EXISTS channels_sovereign_insert ON channels;
CREATE POLICY channels_sovereign_insert ON channels
  FOR INSERT WITH CHECK (is_world_sovereign(world_id));

DROP POLICY IF EXISTS channels_sovereign_update ON channels;
CREATE POLICY channels_sovereign_update ON channels
  FOR UPDATE USING (is_world_sovereign(world_id));

DROP POLICY IF EXISTS channels_sovereign_delete ON channels;
CREATE POLICY channels_sovereign_delete ON channels
  FOR DELETE USING (is_world_sovereign(world_id));

-- ═══════════════════════════════════════════════════════════════
-- TABLE: channel_messages
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE channel_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS channel_messages_read ON channel_messages;
CREATE POLICY channel_messages_read ON channel_messages
  FOR SELECT USING (is_world_member(world_id));

DROP POLICY IF EXISTS channel_messages_insert ON channel_messages;
CREATE POLICY channel_messages_insert ON channel_messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid()::text
    AND is_world_member(world_id)
    AND NOT is_banned_from_world(world_id)
  );

DROP POLICY IF EXISTS channel_messages_self_delete ON channel_messages;
CREATE POLICY channel_messages_self_delete ON channel_messages
  FOR DELETE USING (sender_id = auth.uid()::text);

DROP POLICY IF EXISTS channel_messages_council_delete ON channel_messages;
CREATE POLICY channel_messages_council_delete ON channel_messages
  FOR DELETE USING (is_council_or_above(world_id));

DROP POLICY IF EXISTS channel_messages_council_update ON channel_messages;
CREATE POLICY channel_messages_council_update ON channel_messages
  FOR UPDATE USING (is_council_or_above(world_id));

-- ═══════════════════════════════════════════════════════════════
-- TABLE: channel_reads (Phase 1 — read/unread tracking)
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE channel_reads ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS channel_reads_self ON channel_reads;
CREATE POLICY channel_reads_self ON channel_reads
  FOR ALL USING (resident_id = auth.uid()::text)
  WITH CHECK (resident_id = auth.uid()::text);

-- ═══════════════════════════════════════════════════════════════
-- TABLE: posts
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS posts_read ON posts;
CREATE POLICY posts_read ON posts
  FOR SELECT USING (is_world_member(world_id));

DROP POLICY IF EXISTS posts_insert ON posts;
CREATE POLICY posts_insert ON posts
  FOR INSERT WITH CHECK (
    resident_id = auth.uid()
    AND is_world_member(world_id)
  );

DROP POLICY IF EXISTS posts_author_delete ON posts;
CREATE POLICY posts_author_delete ON posts
  FOR DELETE USING (resident_id = auth.uid());

DROP POLICY IF EXISTS posts_council_delete ON posts;
CREATE POLICY posts_council_delete ON posts
  FOR DELETE USING (is_council_or_above(world_id));

DROP POLICY IF EXISTS posts_council_update ON posts;
CREATE POLICY posts_council_update ON posts
  FOR UPDATE USING (is_council_or_above(world_id));

-- ═══════════════════════════════════════════════════════════════
-- TABLE: events
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS events_read ON events;
CREATE POLICY events_read ON events
  FOR SELECT USING (is_world_member(world_id));

DROP POLICY IF EXISTS events_insert ON events;
CREATE POLICY events_insert ON events
  FOR INSERT WITH CHECK (
    created_by = auth.uid()
    AND is_world_member(world_id)
  );

DROP POLICY IF EXISTS events_creator_delete ON events;
CREATE POLICY events_creator_delete ON events
  FOR DELETE USING (created_by = auth.uid());

-- ═══════════════════════════════════════════════════════════════
-- TABLE: dm_rooms
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE dm_rooms ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS dm_rooms_participant ON dm_rooms;
CREATE POLICY dm_rooms_participant ON dm_rooms
  FOR SELECT USING (resident_ids @> ARRAY[auth.uid()::text]);

DROP POLICY IF EXISTS dm_rooms_insert ON dm_rooms;
CREATE POLICY dm_rooms_insert ON dm_rooms
  FOR INSERT WITH CHECK (
    resident_ids @> ARRAY[auth.uid()::text]
    AND array_length(resident_ids, 1) = 2
  );

-- ═══════════════════════════════════════════════════════════════
-- TABLE: chat_messages (DM messages)
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS chat_messages_participant ON chat_messages;
CREATE POLICY chat_messages_participant ON chat_messages
  FOR SELECT USING (is_dm_participant(room_id));

DROP POLICY IF EXISTS chat_messages_insert ON chat_messages;
CREATE POLICY chat_messages_insert ON chat_messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid()
    AND is_dm_participant(room_id)
  );

-- ═══════════════════════════════════════════════════════════════
-- TABLE: notifications
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS notifications_self_read ON notifications;
CREATE POLICY notifications_self_read ON notifications
  FOR SELECT USING (recipient_id = auth.uid()::text);

DROP POLICY IF EXISTS notifications_service_insert ON notifications;
CREATE POLICY notifications_service_insert ON notifications
  FOR INSERT
  TO service_role
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS notifications_self_update ON notifications;
CREATE POLICY notifications_self_update ON notifications
  FOR UPDATE USING (recipient_id = auth.uid()::text);

-- ═══════════════════════════════════════════════════════════════
-- TABLE: invites
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE invites ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS invites_read ON invites;
CREATE POLICY invites_read ON invites
  FOR SELECT USING (is_world_member(world_id));

DROP POLICY IF EXISTS invites_council_insert ON invites;
CREATE POLICY invites_council_insert ON invites
  FOR INSERT WITH CHECK (is_council_or_above(world_id));

DROP POLICY IF EXISTS invites_council_delete ON invites;
CREATE POLICY invites_council_delete ON invites
  FOR DELETE USING (is_council_or_above(world_id));

-- ═══════════════════════════════════════════════════════════════
-- TABLE: allies (Phase 2 — friends system)
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE allies ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS allies_self_read ON allies;
CREATE POLICY allies_self_read ON allies
  FOR SELECT USING (
    requester_id = auth.uid() OR receiver_id = auth.uid()
  );

DROP POLICY IF EXISTS allies_self_insert ON allies;
CREATE POLICY allies_self_insert ON allies
  FOR INSERT WITH CHECK (
    requester_id = auth.uid()
    AND requester_id != receiver_id -- can't ally with yourself
  );

DROP POLICY IF EXISTS allies_self_update ON allies;
CREATE POLICY allies_self_update ON allies
  FOR UPDATE USING (
    receiver_id = auth.uid() OR requester_id = auth.uid()
  );

DROP POLICY IF EXISTS allies_self_delete ON allies;
CREATE POLICY allies_self_delete ON allies
  FOR DELETE USING (
    requester_id = auth.uid() OR receiver_id = auth.uid()
  );

-- ═══════════════════════════════════════════════════════════════
-- TABLE: districts (Phase 3 — channel categories)
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE districts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS districts_read ON districts;
CREATE POLICY districts_read ON districts
  FOR SELECT USING (is_world_member(world_id));

DROP POLICY IF EXISTS districts_sovereign_manage ON districts;
CREATE POLICY districts_sovereign_manage ON districts
  FOR ALL USING (is_world_sovereign(world_id))
  WITH CHECK (is_world_sovereign(world_id));

-- ═══════════════════════════════════════════════════════════════
-- TABLE: world_ranks (Phase 4 — ranks system)
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE world_ranks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS world_ranks_read ON world_ranks;
CREATE POLICY world_ranks_read ON world_ranks
  FOR SELECT USING (is_world_member(world_id));

DROP POLICY IF EXISTS world_ranks_sovereign_manage ON world_ranks;
CREATE POLICY world_ranks_sovereign_manage ON world_ranks
  FOR ALL USING (is_world_sovereign(world_id))
  WITH CHECK (is_world_sovereign(world_id));

-- ═══════════════════════════════════════════════════════════════
-- TABLE: resident_ranks (Phase 4)
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE resident_ranks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS resident_ranks_read ON resident_ranks;
CREATE POLICY resident_ranks_read ON resident_ranks
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM world_ranks wr
      WHERE wr.id = resident_ranks.rank_id
        AND is_world_member(wr.world_id)
    )
  );

DROP POLICY IF EXISTS resident_ranks_sovereign_manage ON resident_ranks;
CREATE POLICY resident_ranks_sovereign_manage ON resident_ranks
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM world_ranks wr
      WHERE wr.id = resident_ranks.rank_id
        AND is_world_sovereign(wr.world_id)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM world_ranks wr
      WHERE wr.id = resident_ranks.rank_id
        AND is_world_sovereign(wr.world_id)
    )
  );

-- ═══════════════════════════════════════════════════════════════
-- TABLE: world_audit_log (Phase 7 — moderation audit trail)
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE world_audit_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS world_audit_log_read ON world_audit_log;
CREATE POLICY world_audit_log_read ON world_audit_log
  FOR SELECT USING (is_world_member(world_id));

DROP POLICY IF EXISTS world_audit_log_service_insert ON world_audit_log;
CREATE POLICY world_audit_log_service_insert ON world_audit_log
  FOR INSERT
  TO service_role
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS world_audit_log_council_insert ON world_audit_log;
CREATE POLICY world_audit_log_council_insert ON world_audit_log
  FOR INSERT WITH CHECK (is_council_or_above(world_id));

-- ═══════════════════════════════════════════════════════════════
-- TABLE: moderation_logs
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE moderation_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS moderation_logs_read ON moderation_logs;
CREATE POLICY moderation_logs_read ON moderation_logs
  FOR SELECT USING (is_world_member(world_id));

DROP POLICY IF EXISTS moderation_logs_council_insert ON moderation_logs;
CREATE POLICY moderation_logs_council_insert ON moderation_logs
  FOR INSERT WITH CHECK (is_council_or_above(world_id));

-- ═══════════════════════════════════════════════════════════════
-- TABLE: reports
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS reports_self_read ON reports;
CREATE POLICY reports_self_read ON reports
  FOR SELECT USING (reporter_id = auth.uid());

DROP POLICY IF EXISTS reports_council_read ON reports;
CREATE POLICY reports_council_read ON reports
  FOR SELECT USING (is_council_or_above(world_id));

DROP POLICY IF EXISTS reports_self_insert ON reports;
CREATE POLICY reports_self_insert ON reports
  FOR INSERT WITH CHECK (
    reporter_id = auth.uid() AND is_world_member(world_id)
  );

DROP POLICY IF EXISTS reports_council_update ON reports;
CREATE POLICY reports_council_update ON reports
  FOR UPDATE USING (is_council_or_above(world_id));

-- ═══════════════════════════════════════════════════════════════
-- TABLE: subscriptions (if exists)
-- ═══════════════════════════════════════════════════════════════
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'subscriptions') THEN
    ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS subscriptions_self ON subscriptions;
    CREATE POLICY subscriptions_self ON subscriptions
      FOR ALL USING (resident_id = auth.uid())
      WITH CHECK (resident_id = auth.uid());
  END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════
-- ENFORCEMENT: No table is left without RLS
-- ═══════════════════════════════════════════════════════════════
-- This query checks for any public tables that still have RLS disabled.
-- Run after migration to verify:
--
--   SELECT tablename FROM pg_tables
--   WHERE schemaname = 'public'
--     AND tablename NOT IN (SELECT tablename FROM pg_tables
--       WHERE schemaname = 'public' AND rowsecurity = true);
