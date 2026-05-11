-- ═══════════════════════════════════════════════════════════════
-- Vertiege — Fresh Start Schema
-- Paste into: https://wjaphoaxalvgjnrwqjwe.supabase.co → SQL Editor
-- ═══════════════════════════════════════════════════════════════

BEGIN;

-- ═══════════════════════════════════════════════════════════════
-- STEP 1: DROP EVERYTHING (reverse dependency order)
-- ═══════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS world_audit_log CASCADE;
DROP TABLE IF EXISTS resident_ranks CASCADE;
DROP TABLE IF EXISTS world_ranks CASCADE;
DROP TABLE IF EXISTS districts CASCADE;
DROP TABLE IF EXISTS allies CASCADE;
DROP TABLE IF EXISTS channel_reads CASCADE;
DROP TABLE IF EXISTS moderation_logs CASCADE;
DROP TABLE IF EXISTS reports CASCADE;
DROP TABLE IF EXISTS channel_messages CASCADE;
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS invites CASCADE;
DROP TABLE IF EXISTS events CASCADE;
DROP TABLE IF EXISTS posts CASCADE;
DROP TABLE IF EXISTS channels CASCADE;
DROP TABLE IF EXISTS world_members CASCADE;
DROP TABLE IF EXISTS dm_rooms CASCADE;
DROP TABLE IF EXISTS worlds CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

DROP FUNCTION IF EXISTS is_world_member CASCADE;
DROP FUNCTION IF EXISTS is_world_sovereign CASCADE;
DROP FUNCTION IF EXISTS is_council_or_above CASCADE;
DROP FUNCTION IF EXISTS is_dm_participant CASCADE;
DROP FUNCTION IF EXISTS is_banned_from_world CASCADE;
DROP FUNCTION IF EXISTS prevent_profile_escalation CASCADE;
DROP FUNCTION IF EXISTS increment_thread_count CASCADE;

-- ═══════════════════════════════════════════════════════════════
-- STEP 2: CREATE ALL TABLES
-- ═══════════════════════════════════════════════════════════════

-- profiles — linked to auth.users via id
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT '',
  bio TEXT NOT NULL DEFAULT '',
  avatar_url TEXT,
  profession TEXT,
  tier INT NOT NULL DEFAULT 1 CHECK (tier BETWEEN 1 AND 5),
  rep INT NOT NULL DEFAULT 0,
  sovereign_coins INT NOT NULL DEFAULT 0,
  streak_count INT NOT NULL DEFAULT 0,
  streak_shields INT NOT NULL DEFAULT 0,
  last_check_in TEXT,
  decorations TEXT[] NOT NULL DEFAULT '{}',
  following UUID[] NOT NULL DEFAULT '{}',
  referral_code TEXT,
  referred_by TEXT,
  fcm_token TEXT,
  totp_secret TEXT,
  totp_enabled BOOLEAN NOT NULL DEFAULT false,
  joined_world_ids UUID[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- worlds
CREATE TABLE worlds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  type TEXT NOT NULL CHECK (type IN ('wealth','profession','dominion')),
  icon TEXT DEFAULT 'public',
  banner TEXT,
  sovereign_id UUID REFERENCES auth.users(id),
  sovereign_name TEXT,
  prestige INT NOT NULL DEFAULT 0,
  member_count INT NOT NULL DEFAULT 0,
  required_tier INT NOT NULL DEFAULT 1,
  required_profession TEXT,
  access_fee DECIMAL DEFAULT 0,
  features JSONB NOT NULL DEFAULT '{}',
  constitution JSONB NOT NULL DEFAULT '{}',
  activity_score INT NOT NULL DEFAULT 0,
  boost_count INT NOT NULL DEFAULT 0,
  last_boost_month INT,
  created_at BIGINT NOT NULL DEFAULT (EXTRACT(EPOCH FROM now()) * 1000)::BIGINT
);
ALTER TABLE worlds ENABLE ROW LEVEL SECURITY;

-- world_members
CREATE TABLE world_members (
  world_id UUID NOT NULL REFERENCES worlds(id) ON DELETE CASCADE,
  resident_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  resident_name TEXT NOT NULL DEFAULT '',
  rep INT NOT NULL DEFAULT 0,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (world_id, resident_id)
);
ALTER TABLE world_members ENABLE ROW LEVEL SECURITY;

-- channels
CREATE TABLE channels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id UUID NOT NULL REFERENCES worlds(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  channel_type TEXT NOT NULL DEFAULT 'text' CHECK (channel_type IN ('text','announcement','feed','voice')),
  ward_id UUID,
  ward_name TEXT,
  position INT NOT NULL DEFAULT 0,
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE channels ENABLE ROW LEVEL SECURITY;

-- channel_messages
CREATE TABLE channel_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id UUID NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  world_id UUID NOT NULL REFERENCES worlds(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sender_name TEXT NOT NULL,
  sender_avatar TEXT,
  content TEXT NOT NULL DEFAULT '',
  image_url TEXT,
  flagged BOOLEAN NOT NULL DEFAULT false,
  is_pinned BOOLEAN NOT NULL DEFAULT false,
  thread_id UUID,
  thread_count INT NOT NULL DEFAULT 0,
  is_thread_starter BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE channel_messages ENABLE ROW LEVEL SECURITY;

-- posts (feed items)
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id UUID NOT NULL REFERENCES worlds(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  author_name TEXT NOT NULL,
  author_avatar TEXT,
  content TEXT NOT NULL DEFAULT '',
  media TEXT[] NOT NULL DEFAULT '{}',
  reactions JSONB NOT NULL DEFAULT '{}',
  comment_count INT NOT NULL DEFAULT 0,
  is_announcement BOOLEAN NOT NULL DEFAULT false,
  is_decree BOOLEAN NOT NULL DEFAULT false,
  is_pinned BOOLEAN NOT NULL DEFAULT false,
  created_at BIGINT NOT NULL DEFAULT (EXTRACT(EPOCH FROM now()) * 1000)::BIGINT
);
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- events
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id UUID NOT NULL REFERENCES worlds(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  starts_at TIMESTAMPTZ NOT NULL,
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rsvp_ids UUID[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- dm_rooms
CREATE TABLE dm_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resident_ids UUID[] NOT NULL,
  names JSONB NOT NULL DEFAULT '{}',
  other_name TEXT,
  other_avatar TEXT,
  last_message TEXT DEFAULT '',
  last_message_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE dm_rooms ENABLE ROW LEVEL SECURITY;

-- chat_messages (DM messages)
CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES dm_rooms(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  message TEXT NOT NULL DEFAULT '',
  world_id UUID,
  post_id UUID,
  read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- invites
CREATE TABLE invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  world_id UUID NOT NULL REFERENCES worlds(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  uses INT NOT NULL DEFAULT 0,
  max_uses INT NOT NULL DEFAULT 50,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE invites ENABLE ROW LEVEL SECURITY;

-- moderation_logs
CREATE TABLE moderation_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id UUID NOT NULL REFERENCES worlds(id) ON DELETE CASCADE,
  moderator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  target_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE moderation_logs ENABLE ROW LEVEL SECURITY;

-- reports
CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id UUID NOT NULL REFERENCES worlds(id) ON DELETE CASCADE,
  reporter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  target_id UUID NOT NULL,
  reason TEXT NOT NULL,
  details TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','reviewed','dismissed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- ── NEW TABLES (Phases 1-7) ──────────────────────────────────

-- channel_reads
CREATE TABLE channel_reads (
  resident_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  channel_id UUID NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  last_read_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (resident_id, channel_id)
);
ALTER TABLE channel_reads ENABLE ROW LEVEL SECURITY;

-- allies
CREATE TABLE allies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','blocked')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (requester_id, receiver_id)
);
ALTER TABLE allies ENABLE ROW LEVEL SECURITY;

-- districts
CREATE TABLE districts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id UUID NOT NULL REFERENCES worlds(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  position INT NOT NULL DEFAULT 0,
  UNIQUE (world_id, name)
);
ALTER TABLE districts ENABLE ROW LEVEL SECURITY;

-- world_ranks
CREATE TABLE world_ranks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id UUID NOT NULL REFERENCES worlds(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT '#CFBCFF',
  is_hoisted BOOLEAN NOT NULL DEFAULT false,
  is_mentionable BOOLEAN NOT NULL DEFAULT false,
  position INT NOT NULL DEFAULT 0,
  edicts JSONB NOT NULL DEFAULT '{}',
  UNIQUE (world_id, name)
);
ALTER TABLE world_ranks ENABLE ROW LEVEL SECURITY;

-- resident_ranks
CREATE TABLE resident_ranks (
  resident_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rank_id UUID NOT NULL REFERENCES world_ranks(id) ON DELETE CASCADE,
  PRIMARY KEY (resident_id, rank_id)
);
ALTER TABLE resident_ranks ENABLE ROW LEVEL SECURITY;

-- world_audit_log
CREATE TABLE world_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id UUID NOT NULL REFERENCES worlds(id) ON DELETE CASCADE,
  actor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  target_id UUID,
  action TEXT NOT NULL,
  details JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE world_audit_log ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- STEP 3: INDEXES
-- ═══════════════════════════════════════════════════════════════
CREATE INDEX idx_world_members_world ON world_members(world_id);
CREATE INDEX idx_world_members_resident ON world_members(resident_id);
CREATE INDEX idx_channels_world ON channels(world_id);
CREATE INDEX idx_channel_messages_channel ON channel_messages(channel_id);
CREATE INDEX idx_channel_messages_world ON channel_messages(world_id);
CREATE INDEX idx_channel_messages_pinned ON channel_messages(channel_id, is_pinned);
CREATE INDEX idx_channel_messages_thread ON channel_messages(thread_id);
CREATE INDEX idx_posts_world ON posts(world_id);
CREATE INDEX idx_events_world ON events(world_id);
CREATE INDEX idx_dm_rooms_resident ON dm_rooms USING GIN (resident_ids);
CREATE INDEX idx_chat_messages_room ON chat_messages(room_id);
CREATE INDEX idx_notifications_recipient ON notifications(recipient_id, created_at DESC);
CREATE INDEX idx_invites_world ON invites(world_id);
CREATE INDEX idx_moderation_world ON moderation_logs(world_id);
CREATE INDEX idx_reports_world ON reports(world_id);
CREATE INDEX idx_allies_requester ON allies(requester_id);
CREATE INDEX idx_allies_receiver ON allies(receiver_id);
CREATE INDEX idx_districts_world ON districts(world_id);
CREATE INDEX idx_ranks_world ON world_ranks(world_id);
CREATE INDEX idx_resident_ranks_resident ON resident_ranks(resident_id);
CREATE INDEX idx_audit_log_world ON world_audit_log(world_id, created_at DESC);

-- ═══════════════════════════════════════════════════════════════
-- STEP 4: HELPER FUNCTIONS (SECURITY DEFINER)
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION is_world_member(check_world_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM world_members
    WHERE world_id = check_world_id AND resident_id = auth.uid()
  );
END; $$;

CREATE OR REPLACE FUNCTION is_world_sovereign(check_world_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM worlds
    WHERE id = check_world_id AND sovereign_id = auth.uid()
  );
END; $$;

CREATE OR REPLACE FUNCTION is_council_or_above(check_world_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM world_members
    WHERE world_id = check_world_id
      AND resident_id = auth.uid() AND rep >= 5000
  ) OR is_world_sovereign(check_world_id);
END; $$;

CREATE OR REPLACE FUNCTION is_dm_participant(check_room_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM dm_rooms
    WHERE id = check_room_id
      AND resident_ids @> ARRAY[auth.uid()]::UUID[]
  );
END; $$;

CREATE OR REPLACE FUNCTION is_banned_from_world(check_world_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM moderation_logs
    WHERE world_id = check_world_id
      AND target_user_id = auth.uid() AND action = 'ban'
  );
END; $$;

CREATE OR REPLACE FUNCTION increment_thread_count(msg_id UUID)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE channel_messages SET thread_count = thread_count + 1 WHERE id = msg_id;
END; $$;

-- ═══════════════════════════════════════════════════════════════
-- STEP 5: RLS POLICIES
-- ═══════════════════════════════════════════════════════════════

-- profiles
CREATE POLICY profiles_self_read ON profiles FOR SELECT USING (id = auth.uid());
CREATE POLICY profiles_public_read ON profiles FOR SELECT USING (true);
CREATE POLICY profiles_self_update ON profiles FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());
CREATE POLICY profiles_auth_insert ON profiles FOR INSERT WITH CHECK (id = auth.uid());
CREATE POLICY profiles_service_insert ON profiles FOR INSERT TO service_role WITH CHECK (true);

-- worlds
CREATE POLICY worlds_public_read ON worlds FOR SELECT USING (true);
CREATE POLICY worlds_sovereign_update ON worlds FOR UPDATE USING (sovereign_id = auth.uid()) WITH CHECK (sovereign_id = auth.uid());
CREATE POLICY worlds_user_insert ON worlds FOR INSERT WITH CHECK (sovereign_id = auth.uid());
CREATE POLICY worlds_service_insert ON worlds FOR INSERT TO service_role WITH CHECK (true);

-- world_members
CREATE POLICY world_members_read ON world_members FOR SELECT USING (is_world_member(world_id));
CREATE POLICY world_members_join ON world_members FOR INSERT WITH CHECK (resident_id = auth.uid() AND NOT is_banned_from_world(world_id));
CREATE POLICY world_members_leave ON world_members FOR DELETE USING (resident_id = auth.uid());
CREATE POLICY world_members_council_remove ON world_members FOR DELETE USING (is_council_or_above(world_id) AND resident_id != auth.uid());

-- channels
CREATE POLICY channels_read ON channels FOR SELECT USING (is_world_member(world_id));
CREATE POLICY channels_sovereign_write ON channels FOR INSERT WITH CHECK (is_world_sovereign(world_id));
CREATE POLICY channels_sovereign_update ON channels FOR UPDATE USING (is_world_sovereign(world_id));
CREATE POLICY channels_sovereign_delete ON channels FOR DELETE USING (is_world_sovereign(world_id));

-- channel_messages
CREATE POLICY channel_messages_read ON channel_messages FOR SELECT USING (is_world_member(world_id));
CREATE POLICY channel_messages_insert ON channel_messages FOR INSERT WITH CHECK (sender_id = auth.uid() AND is_world_member(world_id) AND NOT is_banned_from_world(world_id));
CREATE POLICY channel_messages_self_delete ON channel_messages FOR DELETE USING (sender_id = auth.uid());
CREATE POLICY channel_messages_council_delete ON channel_messages FOR DELETE USING (is_council_or_above(world_id));
CREATE POLICY channel_messages_council_update ON channel_messages FOR UPDATE USING (is_council_or_above(world_id));

-- channel_reads
CREATE POLICY channel_reads_self ON channel_reads FOR ALL USING (resident_id = auth.uid()) WITH CHECK (resident_id = auth.uid());

-- posts
CREATE POLICY posts_read ON posts FOR SELECT USING (is_world_member(world_id));
CREATE POLICY posts_insert ON posts FOR INSERT WITH CHECK (author_id = auth.uid() AND is_world_member(world_id));
CREATE POLICY posts_author_delete ON posts FOR DELETE USING (author_id = auth.uid());
CREATE POLICY posts_council_delete ON posts FOR DELETE USING (is_council_or_above(world_id));
CREATE POLICY posts_council_update ON posts FOR UPDATE USING (is_council_or_above(world_id));

-- events
CREATE POLICY events_read ON events FOR SELECT USING (is_world_member(world_id));
CREATE POLICY events_insert ON events FOR INSERT WITH CHECK (created_by = auth.uid() AND is_world_member(world_id));
CREATE POLICY events_creator_delete ON events FOR DELETE USING (created_by = auth.uid());

-- dm_rooms
CREATE POLICY dm_rooms_participant ON dm_rooms FOR SELECT USING (resident_ids @> ARRAY[auth.uid()]::UUID[]);
CREATE POLICY dm_rooms_insert ON dm_rooms FOR INSERT WITH CHECK (resident_ids @> ARRAY[auth.uid()]::UUID[] AND array_length(resident_ids, 1) = 2);

-- chat_messages
CREATE POLICY chat_messages_participant ON chat_messages FOR SELECT USING (is_dm_participant(room_id));
CREATE POLICY chat_messages_insert ON chat_messages FOR INSERT WITH CHECK (sender_id = auth.uid() AND is_dm_participant(room_id));

-- notifications
CREATE POLICY notifications_self_read ON notifications FOR SELECT USING (recipient_id = auth.uid());
CREATE POLICY notifications_service_insert ON notifications FOR INSERT TO service_role WITH CHECK (true);
CREATE POLICY notifications_self_update ON notifications FOR UPDATE USING (recipient_id = auth.uid());

-- invites
CREATE POLICY invites_read ON invites FOR SELECT USING (is_world_member(world_id));
CREATE POLICY invites_council_write ON invites FOR INSERT WITH CHECK (is_council_or_above(world_id));
CREATE POLICY invites_council_delete ON invites FOR DELETE USING (is_council_or_above(world_id));

-- allies
CREATE POLICY allies_self_read ON allies FOR SELECT USING (requester_id = auth.uid() OR receiver_id = auth.uid());
CREATE POLICY allies_self_insert ON allies FOR INSERT WITH CHECK (requester_id = auth.uid() AND requester_id != receiver_id);
CREATE POLICY allies_self_update ON allies FOR UPDATE USING (receiver_id = auth.uid() OR requester_id = auth.uid());
CREATE POLICY allies_self_delete ON allies FOR DELETE USING (requester_id = auth.uid() OR receiver_id = auth.uid());

-- districts
CREATE POLICY districts_read ON districts FOR SELECT USING (is_world_member(world_id));
CREATE POLICY districts_sovereign_manage ON districts FOR ALL USING (is_world_sovereign(world_id)) WITH CHECK (is_world_sovereign(world_id));

-- world_ranks
CREATE POLICY world_ranks_read ON world_ranks FOR SELECT USING (is_world_member(world_id));
CREATE POLICY world_ranks_sovereign_manage ON world_ranks FOR ALL USING (is_world_sovereign(world_id)) WITH CHECK (is_world_sovereign(world_id));

-- resident_ranks
CREATE POLICY resident_ranks_read ON resident_ranks FOR SELECT USING (
  EXISTS (SELECT 1 FROM world_ranks wr WHERE wr.id = resident_ranks.rank_id AND is_world_member(wr.world_id))
);
CREATE POLICY resident_ranks_sovereign_manage ON resident_ranks FOR ALL USING (
  EXISTS (SELECT 1 FROM world_ranks wr WHERE wr.id = resident_ranks.rank_id AND is_world_sovereign(wr.world_id))
) WITH CHECK (
  EXISTS (SELECT 1 FROM world_ranks wr WHERE wr.id = resident_ranks.rank_id AND is_world_sovereign(wr.world_id))
);

-- world_audit_log
CREATE POLICY world_audit_log_read ON world_audit_log FOR SELECT USING (is_world_member(world_id));
CREATE POLICY world_audit_log_service_insert ON world_audit_log FOR INSERT TO service_role WITH CHECK (true);
CREATE POLICY world_audit_log_council_insert ON world_audit_log FOR INSERT WITH CHECK (is_council_or_above(world_id));

-- moderation_logs
CREATE POLICY moderation_logs_read ON moderation_logs FOR SELECT USING (is_world_member(world_id));
CREATE POLICY moderation_logs_council_insert ON moderation_logs FOR INSERT WITH CHECK (is_council_or_above(world_id));

-- reports
CREATE POLICY reports_self_read ON reports FOR SELECT USING (reporter_id = auth.uid());
CREATE POLICY reports_council_read ON reports FOR SELECT USING (is_council_or_above(world_id));
CREATE POLICY reports_self_insert ON reports FOR INSERT WITH CHECK (reporter_id = auth.uid() AND is_world_member(world_id));
CREATE POLICY reports_council_update ON reports FOR UPDATE USING (is_council_or_above(world_id));

-- ═══════════════════════════════════════════════════════════════
-- STEP 6: ANTI-ESCALATION TRIGGER
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION prevent_profile_escalation()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND auth.uid() IS NOT NULL
     AND (SELECT role FROM auth.users WHERE id = auth.uid()) != 'service_role' THEN
    IF NEW.rep != OLD.rep THEN RAISE EXCEPTION '[RLS] rep cannot be modified directly'; END IF;
    IF NEW.sovereign_coins != OLD.sovereign_coins THEN RAISE EXCEPTION '[RLS] coins cannot be modified directly'; END IF;
  END IF;
  RETURN NEW;
END; $$;

CREATE TRIGGER trg_prevent_escalation
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION prevent_profile_escalation();

COMMIT;

-- ═══════════════════════════════════════════════════════════════
-- VERIFY (run separately after COMMIT)
-- ═══════════════════════════════════════════════════════════════
-- SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;
-- SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = false;
