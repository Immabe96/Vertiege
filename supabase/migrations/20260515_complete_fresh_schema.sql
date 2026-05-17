-- Vertiege — Complete Fresh Schema (20260515)
-- ⚠️ WARNING: This drops ALL existing data. Run only on a fresh project or after backup.
-- Apply via: Supabase SQL Editor → Run all

-- ═══════════════════════════════════════════════════════════════
-- 0. NUCLEAR OPTION: Drop everything
-- ═══════════════════════════════════════════════════════════════

-- Drop triggers first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS trg_world_members_count ON public.world_members;
DROP TRIGGER IF EXISTS trg_prevent_escalation ON public.profiles;

-- Drop functions
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.prevent_profile_escalation() CASCADE;
DROP FUNCTION IF EXISTS public.update_world_member_count() CASCADE;
DROP FUNCTION IF EXISTS public.increment_world_members(TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.decrement_world_members(TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.increment_thread_count(TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.increment_comment_count(TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.toggle_reaction(TEXT, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.add_comment(TEXT, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.add_reaction(TEXT, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.remove_reaction(TEXT, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.is_world_member(TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.is_world_sovereign(TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.is_council_or_above(TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.is_dm_participant(TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.is_banned_from_world(TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.auto_join_default_channels() CASCADE;
DROP FUNCTION IF EXISTS public.cleanup_resident_on_leave() CASCADE;

-- Drop private schema
DROP SCHEMA IF EXISTS private CASCADE;

-- Drop all public tables (cascade removes policies, indexes, etc.)
DROP TABLE IF EXISTS public.user_achievements CASCADE;
DROP TABLE IF EXISTS public.world_audit_log CASCADE;
DROP TABLE IF EXISTS public.moderation_logs CASCADE;
DROP TABLE IF EXISTS public.reports CASCADE;
DROP TABLE IF EXISTS public.resident_ranks CASCADE;
DROP TABLE IF EXISTS public.world_ranks CASCADE;
DROP TABLE IF EXISTS public.districts CASCADE;
DROP TABLE IF EXISTS public.allies CASCADE;
DROP TABLE IF EXISTS public.channel_reads CASCADE;
DROP TABLE IF EXISTS public.channel_messages CASCADE;
DROP TABLE IF EXISTS public.chat_messages CASCADE;
DROP TABLE IF EXISTS public.dm_rooms CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.invites CASCADE;
DROP TABLE IF EXISTS public.events CASCADE;
DROP TABLE IF EXISTS public.posts CASCADE;
DROP TABLE IF EXISTS public.channels CASCADE;
DROP TABLE IF EXISTS public.world_members CASCADE;
DROP TABLE IF EXISTS public.worlds CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.verification_submissions CASCADE;
DROP TABLE IF EXISTS public.subscriptions CASCADE;

-- Drop storage policies
DROP POLICY IF EXISTS avatars_upload ON storage.objects;
DROP POLICY IF EXISTS avatars_read ON storage.objects;
DROP POLICY IF EXISTS post_media_upload ON storage.objects;
DROP POLICY IF EXISTS post_media_read ON storage.objects;
DROP POLICY IF EXISTS verification_proofs_upload ON storage.objects;
DROP POLICY IF EXISTS verification_proofs_read ON storage.objects;
DROP POLICY IF EXISTS achievement_proofs_upload ON storage.objects;
DROP POLICY IF EXISTS achievement_proofs_read ON storage.objects;

-- Note: Old storage buckets must be deleted manually via Supabase Dashboard
-- (Storage → delete avatars, post-media, verification-proofs, achievement-proofs)
-- The INSERT below uses ON CONFLICT DO NOTHING to safely create them.

-- ═══════════════════════════════════════════════════════════════
-- 1. Extension
-- ═══════════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ═══════════════════════════════════════════════════════════════
-- 2. Profiles (residents)
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE public.profiles (
  id                    TEXT PRIMARY KEY,
  name                  TEXT NOT NULL,
  bio                   TEXT DEFAULT '',
  tier                  INT DEFAULT 1,
  avatar_url            TEXT DEFAULT '',
  profession            TEXT,
  verified_roles        TEXT[] DEFAULT '{}',
  decorations           TEXT[] DEFAULT '{}',
  wealth_worlds_unlocked TEXT[] DEFAULT '{}',
  badges                TEXT[] DEFAULT '{}',
  cosmetics             JSONB DEFAULT '{"badges":[]}',
  last_check_in         TEXT,
  streak_count          INT DEFAULT 0,
  streak_shields        INT DEFAULT 0,
  following             TEXT[] DEFAULT '{}',
  joined_world_ids      TEXT[] DEFAULT '{}',
  local_world_ids       TEXT[] DEFAULT '{}',
  world_standings       JSONB DEFAULT '{}',
  banned_world_ids      TEXT[] DEFAULT '{}',
  muted_until           JSONB DEFAULT '{}',
  sovereign_coins       INT DEFAULT 0,
  referred_by           TEXT,
  gate_interest         TEXT,
  fcm_token             TEXT,
  onboarding_completed  BOOLEAN DEFAULT false,
  gate_completed        BOOLEAN DEFAULT false,
  last_seen_at          BIGINT DEFAULT 0,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- 3. Worlds
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE public.worlds (
  id              TEXT PRIMARY KEY,
  name            TEXT NOT NULL,
  slug            TEXT,
  type            TEXT NOT NULL DEFAULT 'wealth',
  description     TEXT DEFAULT '',
  banner          TEXT,
  sovereign_id    TEXT REFERENCES public.profiles(id), -- NULL until a resident claims sovereignty
  sovereign_name  TEXT NOT NULL,
  prestige        INT DEFAULT 1,
  member_count    INT DEFAULT 0,
  icon            TEXT DEFAULT 'earth',
  required_tier   INT,
  required_profession TEXT,
  is_default      BOOLEAN NOT NULL DEFAULT false,
  sort_order      INT NOT NULL DEFAULT 0,
  activity_score  INT DEFAULT 0,
  boost_count     INT DEFAULT 0,
  last_boost_month TEXT,
  constitution    JSONB DEFAULT '{}',
  created_at      TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.worlds ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- 4. World Members
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE public.world_members (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  world_id      TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  resident_id   TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  resident_name TEXT NOT NULL,
  rep           INT DEFAULT 0,
  joined_at     TIMESTAMPTZ DEFAULT now(),
  UNIQUE(world_id, resident_id)
);

ALTER TABLE public.world_members ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- 5. Channels
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE public.channels (
  id            TEXT PRIMARY KEY,
  world_id      TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  description   TEXT,
  channel_type  TEXT DEFAULT 'text',
  ward_id       UUID,
  ward_name     TEXT,
  position      INT DEFAULT 0,
  is_default    BOOLEAN DEFAULT false,
  created_at    TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.channels ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- 6. Posts
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE public.posts (
  id              TEXT PRIMARY KEY,
  world_id        TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  resident_id     TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  author_id       TEXT,
  resident_name   TEXT NOT NULL,
  author_name     TEXT,
  resident_avatar TEXT DEFAULT '',
  author_avatar   TEXT,
  content         TEXT NOT NULL,
  image_url       TEXT,
  media           JSONB DEFAULT '[]',
  tier_at_posting INT DEFAULT 1,
  is_announcement BOOLEAN DEFAULT false,
  is_decree       BOOLEAN NOT NULL DEFAULT false,
  is_pinned       BOOLEAN DEFAULT false,
  is_edited       BOOLEAN DEFAULT false,
  status          TEXT DEFAULT 'active',
  comment_count   INT NOT NULL DEFAULT 0,
  reactions       JSONB DEFAULT '{}',
  comments        JSONB DEFAULT '[]',
  created_at      TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- 7. Events
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE public.events (
  id              TEXT PRIMARY KEY,
  world_id        TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  description     TEXT DEFAULT '',
  created_by      TEXT NOT NULL REFERENCES public.profiles(id),
  created_by_name TEXT NOT NULL,
  starts_at       BIGINT NOT NULL,
  ends_at         BIGINT,
  rsvp_ids        TEXT[] DEFAULT '{}',
  created_at      TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- 8. DM Rooms
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE public.dm_rooms (
  id              TEXT PRIMARY KEY,
  resident_ids    TEXT[] NOT NULL,
  names           JSONB DEFAULT '{}',
  last_message    TEXT,
  last_message_at TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.dm_rooms ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- 9. Chat Messages (DM)
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE public.chat_messages (
  id                TEXT PRIMARY KEY,
  room_id           TEXT NOT NULL REFERENCES public.dm_rooms(id) ON DELETE CASCADE,
  sender_id         TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  sender_name       TEXT,
  sender_avatar     TEXT,
  content           TEXT NOT NULL,
  image_url         TEXT,
  reply_to_message_id TEXT,
  reply_to_sender_id  TEXT,
  reply_to_sender_name TEXT,
  reply_to_content    TEXT,
  is_edited         BOOLEAN NOT NULL DEFAULT false,
  edited_at         TIMESTAMPTZ,
  is_deleted        BOOLEAN NOT NULL DEFAULT false,
  created_at        TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- 10. Channel Messages
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE public.channel_messages (
  id                TEXT PRIMARY KEY,
  channel_id        TEXT NOT NULL REFERENCES public.channels(id) ON DELETE CASCADE,
  world_id          TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  sender_id         TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  sender_name       TEXT NOT NULL,
  sender_avatar     TEXT,
  content           TEXT NOT NULL,
  image_url         TEXT,
  thread_id         TEXT,
  thread_count      INT NOT NULL DEFAULT 0,
  is_thread_starter BOOLEAN NOT NULL DEFAULT false,
  is_pinned         BOOLEAN NOT NULL DEFAULT false,
  reactions         JSONB DEFAULT '{}',
  flagged           BOOLEAN NOT NULL DEFAULT false,
  reply_to_message_id TEXT,
  reply_to_sender_id  TEXT,
  reply_to_sender_name TEXT,
  reply_to_content    TEXT,
  is_edited         BOOLEAN NOT NULL DEFAULT false,
  edited_at         TIMESTAMPTZ,
  is_deleted        BOOLEAN NOT NULL DEFAULT false,
  created_at        TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.channel_messages ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- 11. Channel Reads
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE public.channel_reads (
  resident_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  channel_id  TEXT NOT NULL,
  last_read_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (resident_id, channel_id)
);

ALTER TABLE public.channel_reads ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- 12. Notifications
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE public.notifications (
  id            TEXT PRIMARY KEY,
  recipient_id  TEXT NOT NULL REFERENCES public.profiles(id),
  type          TEXT NOT NULL,
  message       TEXT NOT NULL,
  world_id      TEXT,
  post_id       TEXT,
  read          BOOLEAN DEFAULT false,
  created_at    TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- 13. Invites
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE public.invites (
  id            TEXT PRIMARY KEY,
  world_id      TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  code          TEXT NOT NULL UNIQUE,
  created_by    TEXT NOT NULL REFERENCES public.profiles(id),
  uses          INT DEFAULT 0,
  max_uses      INT DEFAULT 10,
  expires_at    BIGINT,
  created_at    TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.invites ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- 14. Reports
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE public.reports (
  id            TEXT PRIMARY KEY,
  world_id      TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  post_id       TEXT NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  reporter_id   TEXT NOT NULL,
  reason        TEXT NOT NULL,
  details       TEXT,
  status        TEXT DEFAULT 'pending',
  created_at    TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- 15. Moderation Logs
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE public.moderation_logs (
  id              TEXT PRIMARY KEY,
  world_id        TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  moderator_id    TEXT NOT NULL REFERENCES public.profiles(id),
  target_user_id  TEXT NOT NULL REFERENCES public.profiles(id),
  action          TEXT NOT NULL,
  reason          TEXT,
  duration_hours  INT,
  created_at      TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.moderation_logs ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- 16. Allies
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE public.allies (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  requester_id  TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  receiver_id   TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status        TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'blocked')),
  created_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE (requester_id, receiver_id)
);

ALTER TABLE public.allies ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- 17. Districts
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE public.districts (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  world_id    TEXT NOT NULL,
  name        TEXT NOT NULL,
  position    INT NOT NULL DEFAULT 0,
  UNIQUE (world_id, name)
);

ALTER TABLE public.districts ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- 18. World Ranks
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE public.world_ranks (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  world_id        TEXT NOT NULL,
  name            TEXT NOT NULL,
  color           TEXT NOT NULL DEFAULT '#CFBCFF',
  is_hoisted      BOOLEAN NOT NULL DEFAULT false,
  is_mentionable  BOOLEAN NOT NULL DEFAULT false,
  position        INT NOT NULL DEFAULT 0,
  edicts          JSONB NOT NULL DEFAULT '{}',
  UNIQUE (world_id, name)
);

ALTER TABLE public.world_ranks ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- 19. Resident Ranks
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE public.resident_ranks (
  resident_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  rank_id     UUID NOT NULL REFERENCES public.world_ranks(id) ON DELETE CASCADE,
  PRIMARY KEY (resident_id, rank_id)
);

ALTER TABLE public.resident_ranks ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- 20. World Audit Log
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE public.world_audit_log (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  world_id    TEXT NOT NULL,
  actor_id    TEXT,
  target_id   TEXT,
  action      TEXT NOT NULL,
  details     JSONB NOT NULL DEFAULT '{}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.world_audit_log ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- 21. Verification Submissions
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE public.verification_submissions (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  resident_id   TEXT NOT NULL REFERENCES public.profiles(id),
  resident_name TEXT NOT NULL,
  profession    TEXT NOT NULL,
  proof_url     TEXT,
  status        TEXT DEFAULT 'pending',
  reviewer_notes TEXT,
  reviewed_by   TEXT,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.verification_submissions ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- 22. User Achievements
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE public.user_achievements (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  achievement_id  TEXT NOT NULL,
  status          TEXT NOT NULL DEFAULT 'locked' CHECK (status IN ('locked', 'submitted', 'verified', 'rejected')),
  proof_uri       TEXT,
  submitted_at    TIMESTAMPTZ,
  verified_at     TIMESTAMPTZ,
  ai_confidence   NUMERIC,
  ai_notes        TEXT,
  UNIQUE (user_id, achievement_id)
);

ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════
-- 23. RLS Helper Functions (public schema, TEXT types)
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.is_world_member(check_world_id TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.world_members
    WHERE world_id = check_world_id
      AND resident_id = auth.uid()::text
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.is_world_sovereign(check_world_id TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.worlds
    WHERE id = check_world_id AND sovereign_id = auth.uid()::text
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.is_council_or_above(check_world_id TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.world_members
    WHERE world_id = check_world_id
      AND resident_id = auth.uid()::text
      AND rep >= 5000
  ) OR public.is_world_sovereign(check_world_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.is_dm_participant(check_room_id TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.dm_rooms
    WHERE id = check_room_id
      AND resident_ids @> ARRAY[auth.uid()::text]
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.is_banned_from_world(check_world_id TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.moderation_logs
    WHERE world_id = check_world_id
      AND target_user_id = auth.uid()::text
      AND action = 'ban'
  );
END;
$$;

-- ═══════════════════════════════════════════════════════════════
-- 24. RLS Policies
-- ═══════════════════════════════════════════════════════════════

-- profiles
DROP POLICY IF EXISTS "profiles_public_read" ON public.profiles;
DROP POLICY IF EXISTS "profiles_self_update" ON public.profiles;
DROP POLICY IF EXISTS "profiles_self_insert" ON public.profiles;
DROP POLICY IF EXISTS "profiles_auth_insert" ON public.profiles;
DROP POLICY IF EXISTS "profiles_auth_update" ON public.profiles;
DROP POLICY IF EXISTS "Anyone can read profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "profiles_self_read" ON public.profiles;
DROP POLICY IF EXISTS "profiles_public_read" ON public.profiles;
DROP POLICY IF EXISTS "profiles_self_update" ON public.profiles;
DROP POLICY IF EXISTS "profiles_service_insert" ON public.profiles;
CREATE POLICY "profiles_public_read" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "profiles_self_update" ON public.profiles FOR UPDATE USING (id = auth.uid()::text) WITH CHECK (id = auth.uid()::text);
CREATE POLICY "profiles_self_insert" ON public.profiles FOR INSERT WITH CHECK (id = auth.uid()::text);

-- worlds
DROP POLICY IF EXISTS "worlds_public_read" ON public.worlds;
DROP POLICY IF EXISTS "worlds_sovereign_update" ON public.worlds;
DROP POLICY IF EXISTS "worlds_council_update" ON public.worlds;
DROP POLICY IF EXISTS "worlds_user_insert" ON public.worlds;
DROP POLICY IF EXISTS "worlds_service_insert" ON public.worlds;
DROP POLICY IF EXISTS "Anyone can read worlds" ON public.worlds;
DROP POLICY IF EXISTS "Sovereign can update world" ON public.worlds;
DROP POLICY IF EXISTS "Users can create worlds" ON public.worlds;
CREATE POLICY "worlds_public_read" ON public.worlds FOR SELECT USING (true);
CREATE POLICY "worlds_sovereign_update" ON public.worlds FOR UPDATE USING (sovereign_id = auth.uid()::text) WITH CHECK (sovereign_id = auth.uid()::text);
CREATE POLICY "worlds_council_update" ON public.worlds FOR UPDATE USING (public.is_council_or_above(id));
CREATE POLICY "worlds_user_insert" ON public.worlds FOR INSERT WITH CHECK (sovereign_id = auth.uid()::text);

-- world_members
DROP POLICY IF EXISTS "world_members_read" ON public.world_members;
DROP POLICY IF EXISTS "world_members_join" ON public.world_members;
DROP POLICY IF EXISTS "world_members_leave" ON public.world_members;
DROP POLICY IF EXISTS "world_members_council_remove" ON public.world_members;
DROP POLICY IF EXISTS "world_members_council_update" ON public.world_members;
DROP POLICY IF EXISTS "world_members_self_update" ON public.world_members;
DROP POLICY IF EXISTS "world_members_self_read" ON public.world_members;
DROP POLICY IF EXISTS "world_members_council_remove" ON public.world_members;
CREATE POLICY "world_members_read" ON public.world_members FOR SELECT USING (resident_id = auth.uid()::text OR public.is_world_member(world_id));
CREATE POLICY "world_members_join" ON public.world_members FOR INSERT WITH CHECK (resident_id = auth.uid()::text AND NOT public.is_banned_from_world(world_id));
CREATE POLICY "world_members_leave" ON public.world_members FOR DELETE USING (resident_id = auth.uid()::text);
CREATE POLICY "world_members_council_remove" ON public.world_members FOR DELETE USING (public.is_council_or_above(world_id) AND resident_id != auth.uid()::text);
CREATE POLICY "world_members_council_update" ON public.world_members FOR UPDATE USING (public.is_council_or_above(world_id));
CREATE POLICY "world_members_self_update" ON public.world_members FOR UPDATE USING (resident_id = auth.uid()::text);

-- channels
DROP POLICY IF EXISTS "channels_read" ON public.channels;
DROP POLICY IF EXISTS "channels_sovereign_insert" ON public.channels;
DROP POLICY IF EXISTS "channels_sovereign_update" ON public.channels;
DROP POLICY IF EXISTS "channels_council_update" ON public.channels;
DROP POLICY IF EXISTS "channels_sovereign_delete" ON public.channels;
DROP POLICY IF EXISTS "channels_council_delete" ON public.channels;
DROP POLICY IF EXISTS "Anyone can read channels" ON public.channels;
DROP POLICY IF EXISTS "World members can create channels" ON public.channels;
CREATE POLICY "channels_read" ON public.channels FOR SELECT USING (public.is_world_member(world_id));
CREATE POLICY "channels_sovereign_insert" ON public.channels FOR INSERT WITH CHECK (public.is_world_sovereign(world_id));
CREATE POLICY "channels_sovereign_update" ON public.channels FOR UPDATE USING (public.is_world_sovereign(world_id));
CREATE POLICY "channels_council_update" ON public.channels FOR UPDATE USING (public.is_council_or_above(world_id));
CREATE POLICY "channels_sovereign_delete" ON public.channels FOR DELETE USING (public.is_world_sovereign(world_id));
CREATE POLICY "channels_council_delete" ON public.channels FOR DELETE USING (public.is_council_or_above(world_id));

-- posts
DROP POLICY IF EXISTS "posts_read" ON public.posts;
DROP POLICY IF EXISTS "posts_insert" ON public.posts;
DROP POLICY IF EXISTS "posts_author_delete" ON public.posts;
DROP POLICY IF EXISTS "posts_council_delete" ON public.posts;
DROP POLICY IF EXISTS "posts_council_update" ON public.posts;
DROP POLICY IF EXISTS "posts_author_update" ON public.posts;
DROP POLICY IF EXISTS "Anyone can read posts" ON public.posts;
DROP POLICY IF EXISTS "World members can create posts" ON public.posts;
DROP POLICY IF EXISTS "Authors can update own posts" ON public.posts;
DROP POLICY IF EXISTS "Authors or moderators can delete posts" ON public.posts;
DROP POLICY IF EXISTS "posts_author_delete" ON public.posts;
DROP POLICY IF EXISTS "posts_insert" ON public.posts;
CREATE POLICY "posts_read" ON public.posts FOR SELECT USING (public.is_world_member(world_id));
CREATE POLICY "posts_insert" ON public.posts FOR INSERT WITH CHECK (resident_id = auth.uid()::text AND public.is_world_member(world_id));
CREATE POLICY "posts_author_delete" ON public.posts FOR DELETE USING (resident_id = auth.uid()::text);
CREATE POLICY "posts_council_delete" ON public.posts FOR DELETE USING (public.is_council_or_above(world_id));
CREATE POLICY "posts_council_update" ON public.posts FOR UPDATE USING (public.is_council_or_above(world_id));
CREATE POLICY "posts_author_update" ON public.posts FOR UPDATE USING (resident_id = auth.uid()::text);

-- events
DROP POLICY IF EXISTS "events_read" ON public.events;
DROP POLICY IF EXISTS "events_insert" ON public.events;
DROP POLICY IF EXISTS "events_creator_delete" ON public.events;
DROP POLICY IF EXISTS "Anyone can read events" ON public.events;
CREATE POLICY "events_read" ON public.events FOR SELECT USING (public.is_world_member(world_id));
CREATE POLICY "events_insert" ON public.events FOR INSERT WITH CHECK (created_by = auth.uid()::text AND public.is_world_member(world_id));
CREATE POLICY "events_creator_delete" ON public.events FOR DELETE USING (created_by = auth.uid()::text);

-- dm_rooms
DROP POLICY IF EXISTS "dm_rooms_participant" ON public.dm_rooms;
DROP POLICY IF EXISTS "dm_rooms_insert" ON public.dm_rooms;
DROP POLICY IF EXISTS "Users can read own DM rooms" ON public.dm_rooms;
CREATE POLICY "dm_rooms_participant" ON public.dm_rooms FOR SELECT USING (resident_ids @> ARRAY[auth.uid()::text]);
CREATE POLICY "dm_rooms_insert" ON public.dm_rooms FOR INSERT WITH CHECK (resident_ids @> ARRAY[auth.uid()::text] AND array_length(resident_ids, 1) = 2);

-- chat_messages
DROP POLICY IF EXISTS "chat_messages_participant" ON public.chat_messages;
DROP POLICY IF EXISTS "chat_messages_insert" ON public.chat_messages;
DROP POLICY IF EXISTS "chat_messages_self_update" ON public.chat_messages;
DROP POLICY IF EXISTS "chat_messages_self_delete" ON public.chat_messages;
DROP POLICY IF EXISTS "Room members can read messages" ON public.chat_messages;
DROP POLICY IF EXISTS "Room members can send messages" ON public.chat_messages;
CREATE POLICY "chat_messages_participant" ON public.chat_messages FOR SELECT USING (public.is_dm_participant(room_id));
CREATE POLICY "chat_messages_insert" ON public.chat_messages FOR INSERT WITH CHECK (sender_id = auth.uid()::text AND public.is_dm_participant(room_id));
CREATE POLICY "chat_messages_self_update" ON public.chat_messages FOR UPDATE USING (sender_id = auth.uid()::text);
CREATE POLICY "chat_messages_self_delete" ON public.chat_messages FOR DELETE USING (sender_id = auth.uid()::text);

-- channel_messages
DROP POLICY IF EXISTS "channel_messages_read" ON public.channel_messages;
DROP POLICY IF EXISTS "channel_messages_insert" ON public.channel_messages;
DROP POLICY IF EXISTS "channel_messages_self_delete" ON public.channel_messages;
DROP POLICY IF EXISTS "channel_messages_council_delete" ON public.channel_messages;
DROP POLICY IF EXISTS "channel_messages_council_update" ON public.channel_messages;
DROP POLICY IF EXISTS "channel_messages_self_update" ON public.channel_messages;
DROP POLICY IF EXISTS "World members can read channel messages" ON public.channel_messages;
DROP POLICY IF EXISTS "World members can send channel messages" ON public.channel_messages;
CREATE POLICY "channel_messages_read" ON public.channel_messages FOR SELECT USING (public.is_world_member(world_id));
CREATE POLICY "channel_messages_insert" ON public.channel_messages FOR INSERT WITH CHECK (sender_id = auth.uid()::text AND public.is_world_member(world_id) AND NOT public.is_banned_from_world(world_id));
CREATE POLICY "channel_messages_self_delete" ON public.channel_messages FOR DELETE USING (sender_id = auth.uid()::text);
CREATE POLICY "channel_messages_council_delete" ON public.channel_messages FOR DELETE USING (public.is_council_or_above(world_id));
CREATE POLICY "channel_messages_council_update" ON public.channel_messages FOR UPDATE USING (public.is_council_or_above(world_id));
CREATE POLICY "channel_messages_self_update" ON public.channel_messages FOR UPDATE USING (sender_id = auth.uid()::text);

-- channel_reads
DROP POLICY IF EXISTS "channel_reads_self" ON public.channel_reads;
CREATE POLICY "channel_reads_self" ON public.channel_reads FOR ALL USING (resident_id = auth.uid()::text) WITH CHECK (resident_id = auth.uid()::text);

-- notifications
DROP POLICY IF EXISTS "notifications_self_read" ON public.notifications;
DROP POLICY IF EXISTS "notifications_insert" ON public.notifications;
DROP POLICY IF EXISTS "notifications_self_update" ON public.notifications;
DROP POLICY IF EXISTS "notifications_service_insert" ON public.notifications;
DROP POLICY IF EXISTS "Users can read own notifications" ON public.notifications;
CREATE POLICY "notifications_self_read" ON public.notifications FOR SELECT USING (recipient_id = auth.uid()::text);
CREATE POLICY "notifications_insert" ON public.notifications FOR INSERT WITH CHECK (true);
CREATE POLICY "notifications_self_update" ON public.notifications FOR UPDATE USING (recipient_id = auth.uid()::text);

-- invites
DROP POLICY IF EXISTS "invites_read" ON public.invites;
DROP POLICY IF EXISTS "invites_council_insert" ON public.invites;
DROP POLICY IF EXISTS "invites_member_insert" ON public.invites;
DROP POLICY IF EXISTS "invites_council_delete" ON public.invites;
DROP POLICY IF EXISTS "Anyone can read invites" ON public.invites;
DROP POLICY IF EXISTS "World members can create invites" ON public.invites;
CREATE POLICY "invites_read" ON public.invites FOR SELECT USING (public.is_world_member(world_id));
CREATE POLICY "invites_council_insert" ON public.invites FOR INSERT WITH CHECK (public.is_council_or_above(world_id));
CREATE POLICY "invites_member_insert" ON public.invites FOR INSERT WITH CHECK (public.is_world_member(world_id));
CREATE POLICY "invites_council_delete" ON public.invites FOR DELETE USING (public.is_council_or_above(world_id));

-- reports
DROP POLICY IF EXISTS "reports_self_read" ON public.reports;
DROP POLICY IF EXISTS "reports_council_read" ON public.reports;
DROP POLICY IF EXISTS "reports_self_insert" ON public.reports;
DROP POLICY IF EXISTS "reports_council_update" ON public.reports;
DROP POLICY IF EXISTS "World moderators can read reports" ON public.reports;
DROP POLICY IF EXISTS "Anyone can create reports" ON public.reports;
CREATE POLICY "reports_self_read" ON public.reports FOR SELECT USING (reporter_id = auth.uid()::text);
CREATE POLICY "reports_council_read" ON public.reports FOR SELECT USING (public.is_council_or_above(world_id));
CREATE POLICY "reports_self_insert" ON public.reports FOR INSERT WITH CHECK (reporter_id = auth.uid()::text AND public.is_world_member(world_id));
CREATE POLICY "reports_council_update" ON public.reports FOR UPDATE USING (public.is_council_or_above(world_id));

-- moderation_logs
DROP POLICY IF EXISTS "moderation_logs_read" ON public.moderation_logs;
DROP POLICY IF EXISTS "moderation_logs_council_insert" ON public.moderation_logs;
DROP POLICY IF EXISTS "moderation_logs_member_insert" ON public.moderation_logs;
DROP POLICY IF EXISTS "World moderators can read logs" ON public.moderation_logs;
CREATE POLICY "moderation_logs_read" ON public.moderation_logs FOR SELECT USING (public.is_world_member(world_id));
CREATE POLICY "moderation_logs_council_insert" ON public.moderation_logs FOR INSERT WITH CHECK (public.is_council_or_above(world_id));
CREATE POLICY "moderation_logs_member_insert" ON public.moderation_logs FOR INSERT WITH CHECK (public.is_world_member(world_id));

-- allies
DROP POLICY IF EXISTS "allies_self_read" ON public.allies;
DROP POLICY IF EXISTS "allies_self_insert" ON public.allies;
DROP POLICY IF EXISTS "allies_self_update" ON public.allies;
DROP POLICY IF EXISTS "allies_self_delete" ON public.allies;
CREATE POLICY "allies_self_read" ON public.allies FOR SELECT USING (requester_id = auth.uid()::text OR receiver_id = auth.uid()::text);
CREATE POLICY "allies_self_insert" ON public.allies FOR INSERT WITH CHECK (requester_id = auth.uid()::text AND requester_id != receiver_id);
CREATE POLICY "allies_self_update" ON public.allies FOR UPDATE USING (receiver_id = auth.uid()::text OR requester_id = auth.uid()::text);
CREATE POLICY "allies_self_delete" ON public.allies FOR DELETE USING (requester_id = auth.uid()::text OR receiver_id = auth.uid()::text);

-- districts
DROP POLICY IF EXISTS "districts_read" ON public.districts;
DROP POLICY IF EXISTS "districts_sovereign_manage" ON public.districts;
CREATE POLICY "districts_read" ON public.districts FOR SELECT USING (public.is_world_member(world_id));
CREATE POLICY "districts_sovereign_manage" ON public.districts FOR ALL USING (public.is_world_sovereign(world_id)) WITH CHECK (public.is_world_sovereign(world_id));

-- world_ranks
DROP POLICY IF EXISTS "world_ranks_read" ON public.world_ranks;
DROP POLICY IF EXISTS "world_ranks_sovereign_manage" ON public.world_ranks;
CREATE POLICY "world_ranks_read" ON public.world_ranks FOR SELECT USING (public.is_world_member(world_id));
CREATE POLICY "world_ranks_sovereign_manage" ON public.world_ranks FOR ALL USING (public.is_world_sovereign(world_id)) WITH CHECK (public.is_world_sovereign(world_id));

-- resident_ranks
DROP POLICY IF EXISTS "resident_ranks_read" ON public.resident_ranks;
DROP POLICY IF EXISTS "resident_ranks_sovereign_manage" ON public.resident_ranks;
CREATE POLICY "resident_ranks_read" ON public.resident_ranks FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.world_ranks wr WHERE wr.id = resident_ranks.rank_id AND public.is_world_member(wr.world_id))
);
CREATE POLICY "resident_ranks_sovereign_manage" ON public.resident_ranks FOR ALL USING (
  EXISTS (SELECT 1 FROM public.world_ranks wr WHERE wr.id = resident_ranks.rank_id AND public.is_world_sovereign(wr.world_id))
) WITH CHECK (
  EXISTS (SELECT 1 FROM public.world_ranks wr WHERE wr.id = resident_ranks.rank_id AND public.is_world_sovereign(wr.world_id))
);

-- world_audit_log
DROP POLICY IF EXISTS "world_audit_log_read" ON public.world_audit_log;
DROP POLICY IF EXISTS "world_audit_log_council_insert" ON public.world_audit_log;
DROP POLICY IF EXISTS "world_audit_log_member_insert" ON public.world_audit_log;
CREATE POLICY "world_audit_log_read" ON public.world_audit_log FOR SELECT USING (public.is_world_member(world_id));
CREATE POLICY "world_audit_log_council_insert" ON public.world_audit_log FOR INSERT WITH CHECK (public.is_council_or_above(world_id));
CREATE POLICY "world_audit_log_member_insert" ON public.world_audit_log FOR INSERT WITH CHECK (public.is_world_member(world_id));

-- verification_submissions
DROP POLICY IF EXISTS "verification_self_read" ON public.verification_submissions;
DROP POLICY IF EXISTS "verification_self_insert" ON public.verification_submissions;
DROP POLICY IF EXISTS "verification_self_update" ON public.verification_submissions;
DROP POLICY IF EXISTS "verification_council_update" ON public.verification_submissions;
DROP POLICY IF EXISTS "Anyone can read own submissions" ON public.verification_submissions;
DROP POLICY IF EXISTS "Users can insert own submissions" ON public.verification_submissions;
DROP POLICY IF EXISTS "Users can update own submissions" ON public.verification_submissions;
CREATE POLICY "verification_self_read" ON public.verification_submissions FOR SELECT USING (resident_id = auth.uid()::text);
CREATE POLICY "verification_self_insert" ON public.verification_submissions FOR INSERT WITH CHECK (resident_id = auth.uid()::text);
CREATE POLICY "verification_self_update" ON public.verification_submissions FOR UPDATE USING (resident_id = auth.uid()::text);
CREATE POLICY "verification_council_update" ON public.verification_submissions FOR UPDATE USING (true);

-- user_achievements
DROP POLICY IF EXISTS "achievements_self_read" ON public.user_achievements;
DROP POLICY IF EXISTS "achievements_self_insert" ON public.user_achievements;
DROP POLICY IF EXISTS "achievements_self_update" ON public.user_achievements;
DROP POLICY IF EXISTS "Users can read own achievements" ON public.user_achievements;
DROP POLICY IF EXISTS "Users can insert own achievements" ON public.user_achievements;
DROP POLICY IF EXISTS "Users can update own achievements" ON public.user_achievements;
CREATE POLICY "achievements_self_read" ON public.user_achievements FOR SELECT USING (user_id = auth.uid()::text);
CREATE POLICY "achievements_self_insert" ON public.user_achievements FOR INSERT WITH CHECK (user_id = auth.uid()::text);
CREATE POLICY "achievements_self_update" ON public.user_achievements FOR UPDATE USING (user_id = auth.uid()::text);

-- ═══════════════════════════════════════════════════════════════
-- 25. Indexes
-- ═══════════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_posts_world_id ON public.posts(world_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON public.posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_author_id ON public.posts(author_id);
CREATE INDEX IF NOT EXISTS idx_world_members_world ON public.world_members(world_id);
CREATE INDEX IF NOT EXISTS idx_world_members_resident ON public.world_members(resident_id);
CREATE INDEX IF NOT EXISTS idx_channel_messages_channel ON public.channel_messages(channel_id);
CREATE INDEX IF NOT EXISTS idx_channel_messages_created ON public.channel_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_channel_messages_sender_id ON public.channel_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_channel_messages_thread ON public.channel_messages(thread_id);
CREATE INDEX IF NOT EXISTS idx_channel_messages_pinned ON public.channel_messages(channel_id, is_pinned);
CREATE INDEX IF NOT EXISTS idx_chat_messages_room ON public.chat_messages(room_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created ON public.chat_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON public.chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON public.notifications(recipient_id);
CREATE INDEX IF NOT EXISTS idx_events_world ON public.events(world_id);
CREATE INDEX IF NOT EXISTS idx_events_created_by ON public.events(created_by);
CREATE INDEX IF NOT EXISTS idx_invites_created_by ON public.invites(created_by);
CREATE INDEX IF NOT EXISTS idx_moderation_logs_moderator_id ON public.moderation_logs(moderator_id);
CREATE INDEX IF NOT EXISTS idx_moderation_logs_target_user_id ON public.moderation_logs(target_user_id);
CREATE INDEX IF NOT EXISTS idx_reports_reporter_id ON public.reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_world_audit_log_actor_id ON public.world_audit_log(actor_id);
CREATE INDEX IF NOT EXISTS idx_worlds_sovereign_id ON public.worlds(sovereign_id);
CREATE INDEX IF NOT EXISTS idx_allies_requester ON public.allies(requester_id);
CREATE INDEX IF NOT EXISTS idx_allies_receiver ON public.allies(receiver_id);
CREATE INDEX IF NOT EXISTS idx_allies_status ON public.allies(status);
CREATE INDEX IF NOT EXISTS idx_districts_world ON public.districts(world_id, position);
CREATE INDEX IF NOT EXISTS idx_resident_ranks_resident ON public.resident_ranks(resident_id);
CREATE INDEX IF NOT EXISTS idx_resident_ranks_rank ON public.resident_ranks(rank_id);
CREATE INDEX IF NOT EXISTS idx_channel_reads_channel_id ON public.channel_reads(channel_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_user ON public.user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_status ON public.user_achievements(status);

-- ═══════════════════════════════════════════════════════════════
-- 26. RPC Functions
-- ═══════════════════════════════════════════════════════════════

-- Toggle reaction on a post
CREATE OR REPLACE FUNCTION public.toggle_reaction(
  post_id TEXT, emoji TEXT, resident_id TEXT
) RETURNS void AS $$
BEGIN
  UPDATE public.posts SET reactions = CASE WHEN reactions ? emoji THEN reactions - emoji ELSE jsonb_set(reactions, ARRAY[emoji], '1'::jsonb) END WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- Add comment to a post
CREATE OR REPLACE FUNCTION public.add_comment(
  post_id TEXT, resident_id TEXT, content TEXT
) RETURNS void AS $$
BEGIN
  UPDATE public.posts SET comments = comments || jsonb_build_object(
    'id', uuid_generate_v4()::text,
    'residentId', resident_id,
    'content', content,
    'timestamp', extract(epoch FROM now()) * 1000
  ) WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- Increment comment count
CREATE OR REPLACE FUNCTION public.increment_comment_count(post_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE public.posts SET comment_count = comment_count + 1 WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- Increment thread count
CREATE OR REPLACE FUNCTION public.increment_thread_count(msg_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE public.channel_messages SET thread_count = thread_count + 1 WHERE id = msg_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- Add reaction to channel message
CREATE OR REPLACE FUNCTION public.add_reaction(msg_id TEXT, emoji TEXT, resident_id TEXT)
RETURNS void AS $$
DECLARE
  current_reactions JSONB;
  user_reactions JSONB;
BEGIN
  SELECT reactions INTO current_reactions FROM public.channel_messages WHERE id = msg_id;
  IF current_reactions IS NULL THEN current_reactions := '{}'::jsonb; END IF;
  user_reactions := current_reactions -> emoji;
  IF user_reactions IS NULL THEN
    UPDATE public.channel_messages SET reactions = jsonb_set(current_reactions, ARRAY[emoji], to_jsonb(resident_id)::jsonb) WHERE id = msg_id;
  ELSE
    IF NOT (user_reactions ? resident_id) THEN
      UPDATE public.channel_messages SET reactions = jsonb_set(current_reactions, ARRAY[emoji], (user_reactions || to_jsonb(resident_id))::jsonb) WHERE id = msg_id;
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- Remove reaction from channel message
CREATE OR REPLACE FUNCTION public.remove_reaction(msg_id TEXT, emoji TEXT, resident_id TEXT)
RETURNS void AS $$
DECLARE
  current_reactions JSONB;
  user_reactions JSONB;
  new_array JSONB;
BEGIN
  SELECT reactions INTO current_reactions FROM public.channel_messages WHERE id = msg_id;
  IF current_reactions IS NULL THEN RETURN; END IF;
  user_reactions := current_reactions -> emoji;
  IF user_reactions IS NULL THEN RETURN; END IF;
  new_array := (SELECT jsonb_agg(elem) FROM jsonb_array_elements(user_reactions) AS elem WHERE elem <> to_jsonb(resident_id));
  IF new_array IS NULL OR jsonb_array_length(new_array) = 0 THEN
    UPDATE public.channel_messages SET reactions = current_reactions - emoji WHERE id = msg_id;
  ELSE
    UPDATE public.channel_messages SET reactions = jsonb_set(current_reactions, ARRAY[emoji], new_array) WHERE id = msg_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- World member count RPCs
CREATE OR REPLACE FUNCTION public.increment_world_members(w_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE public.worlds SET member_count = member_count + 1 WHERE id = w_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

CREATE OR REPLACE FUNCTION public.decrement_world_members(w_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE public.worlds SET member_count = GREATEST(member_count - 1, 0) WHERE id = w_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- ═══════════════════════════════════════════════════════════════
-- 27. Triggers
-- ═══════════════════════════════════════════════════════════════

-- Auto-create profile on auth signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  INSERT INTO public.profiles (id, name, bio, tier, avatar_url)
  VALUES (NEW.id::text, COALESCE(NEW.raw_user_meta_data->>'name', 'New Resident'), '', 1, '');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Auto-update world member_count
CREATE OR REPLACE FUNCTION public.update_world_member_count()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.worlds SET member_count = member_count + 1 WHERE id = NEW.world_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.worlds SET member_count = GREATEST(member_count - 1, 0) WHERE id = OLD.world_id;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_world_members_count ON public.world_members;
CREATE TRIGGER trg_world_members_count
  AFTER INSERT OR DELETE ON public.world_members
  FOR EACH ROW EXECUTE FUNCTION public.update_world_member_count();

-- Prevent profile escalation
CREATE OR REPLACE FUNCTION public.prevent_profile_escalation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND auth.uid() IS NOT NULL THEN
    IF NEW.tier != OLD.tier AND OLD.tier IS NOT NULL THEN
      RAISE EXCEPTION 'tier cannot be modified directly';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_escalation ON public.profiles;
CREATE TRIGGER trg_prevent_escalation
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.prevent_profile_escalation();

-- Auto-join default channels
CREATE OR REPLACE FUNCTION public.auto_join_default_channels()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.channel_reads (resident_id, channel_id, last_read_at)
  SELECT NEW.resident_id, c.id, now()
  FROM public.channels c
  WHERE c.world_id = NEW.world_id AND c.is_default = true
  ON CONFLICT (resident_id, channel_id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- Cleanup on leave
CREATE OR REPLACE FUNCTION public.cleanup_resident_on_leave()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM public.resident_ranks WHERE resident_id = OLD.resident_id
    AND rank_id IN (SELECT id FROM public.world_ranks WHERE world_id = OLD.world_id);
  RETURN OLD;
END;
$$;

-- ═══════════════════════════════════════════════════════════════
-- 28. Storage Buckets
-- ═══════════════════════════════════════════════════════════════

INSERT INTO storage.buckets (id, name, public) VALUES
  ('avatars', 'avatars', true),
  ('post-media', 'post-media', true),
  ('verification-proofs', 'verification-proofs', false),
  ('achievement-proofs', 'achievement-proofs', false)
ON CONFLICT (id) DO NOTHING;

-- avatars
CREATE POLICY "avatars_upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');
CREATE POLICY "avatars_read" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');

-- post-media
CREATE POLICY "post_media_upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'post-media' AND auth.role() = 'authenticated');
CREATE POLICY "post_media_read" ON storage.objects FOR SELECT USING (bucket_id = 'post-media');

-- verification-proofs
CREATE POLICY "verification_proofs_upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'verification-proofs' AND auth.role() = 'authenticated');
CREATE POLICY "verification_proofs_read" ON storage.objects FOR SELECT USING (bucket_id = 'verification-proofs' AND auth.role() = 'authenticated');

-- achievement-proofs
CREATE POLICY "achievement_proofs_upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'achievement-proofs' AND auth.role() = 'authenticated');
CREATE POLICY "achievement_proofs_read" ON storage.objects FOR SELECT USING (bucket_id = 'achievement-proofs' AND auth.role() = 'authenticated');

-- ═══════════════════════════════════════════════════════════════
-- 29. Realtime
-- ═══════════════════════════════════════════════════════════════

ALTER PUBLICATION supabase_realtime ADD TABLE public.channel_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.posts;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- ═══════════════════════════════════════════════════════════════
-- 30. Grant execute on helper functions
-- ═══════════════════════════════════════════════════════════════

GRANT EXECUTE ON FUNCTION public.is_world_member(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_world_sovereign(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_council_or_above(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_dm_participant(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_banned_from_world(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_thread_count(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_comment_count(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_world_members(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.decrement_world_members(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.add_reaction(TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.remove_reaction(TEXT, TEXT, TEXT) TO authenticated;

-- ═══════════════════════════════════════════════════════════════
-- SEED: Premade Worlds
-- ═══════════════════════════════════════════════════════════════
INSERT INTO worlds (id, slug, name, type, description, sovereign_id, sovereign_name, prestige, icon, required_tier, required_profession) VALUES
('neon-district', 'neon-district', 'Neon District', 'wealth', 'The entry point to the digital realm. Neon lights and endless opportunity.', NULL, 'The Architect', 5, 'neon', 1, NULL),
('azure-coast', 'azure-coast', 'Azure Coast', 'wealth', 'Pristine shores where the High Rollers gather to shape the economy.', NULL, 'Countess Voss', 12, 'azure', 2, NULL),
('sovereign-city', 'sovereign-city', 'Sovereign City', 'wealth', 'The capital of power. Only the Elite tread these gilded streets.', NULL, 'Chancellor Vale', 22, 'sovereign', 3, NULL),
('golden-estate', 'golden-estate', 'Golden Estate', 'wealth', 'Old Money estates sprawling across manicured landscapes.', NULL, 'Lord Ashford', 35, 'golden', 4, NULL),
('aetheria', 'aetheria', 'Aetheria', 'wealth', 'The mythical apex realm where legends are forged.', NULL, 'The Oracle', 48, 'aetheria', 5, NULL),
('aviation-heights', 'aviation-heights', 'Aviation Heights', 'profession', 'Where pilots and aerospace innovators push the boundaries of flight.', NULL, 'Captain Storm', 18, 'aviation', NULL, 'Aviation'),
('medical-nexus', 'medical-nexus', 'Medical Nexus', 'profession', 'The cutting edge of medicine where healers advance their craft.', NULL, 'Dean Hippocrates', 28, 'medical', NULL, 'Medical'),
('financial-district', 'financial-district', 'Financial District', 'profession', 'The heart of capital where financiers move markets.', NULL, 'Baron Roth', 32, 'finance', NULL, 'Finance'),
('tech-sprawl', 'tech-sprawl', 'Tech Sprawl', 'profession', 'A sprawling digital metropolis for the architects of code.', NULL, 'Architect Kai', 25, 'tech', NULL, 'Technology'),
('legal-plaza', 'legal-plaza', 'Legal Plaza', 'profession', 'Where law and order shape the framework of society.', NULL, 'Justice Thorne', 20, 'legal', NULL, 'Legal'),
('arts-pavilion', 'arts-pavilion', 'Arts Pavilion', 'profession', 'A sanctuary of creativity where artists bring beauty to life.', NULL, 'Curator Noire', 15, 'arts', NULL, 'Arts'),
('crystal-shore', 'crystal-shore', 'Crystal Shore', 'wealth', 'Shimmering crystal beaches open to all newcomers.', NULL, 'Admiral Tide', 3, 'crystal', 1, NULL),
('quantum-core', 'quantum-core', 'Quantum Core', 'profession', 'The bleeding edge of engineering and quantum mechanics.', NULL, 'Dr. Flux', 24, 'quantum', NULL, 'Engineer'),
('silver-page', 'silver-page', 'Silver Page', 'profession', 'A quiet library realm where wordsmiths and storytellers dwell.', NULL, 'Scribe Aurelius', 10, 'silver', NULL, 'Artist'),
('crimson-court', 'crimson-court', 'Crimson Court', 'wealth', 'A velvet-draped court of intrigue for discerning High Rollers.', NULL, 'Duchess Scarlett', 16, 'crimson', 2, NULL),
('nova-station', 'nova-station', 'Nova Station', 'wealth', 'A deep-space outpost orbiting the frontier of the known universe.', NULL, 'Commander Vega', 42, 'nova', 5, NULL)
ON CONFLICT (id) DO UPDATE SET slug = EXCLUDED.slug;

-- ═══════════════════════════════════════════════════════════════
-- DONE — Schema is fresh and consistent.
-- ═══════════════════════════════════════════════════════════════
