-- Vertiege — Complete Supabase Schema
-- Apply this migration via: supabase db push
-- Or copy into Supabase SQL Editor

-- ── Enable UUID generation ──────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── Phase 1: Channel Reads (read/unread tracking) ──────────
CREATE TABLE IF NOT EXISTS channel_reads (
  resident_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  channel_id TEXT NOT NULL,
  last_read_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (resident_id, channel_id)
);

-- ── Phase 2: Allies (friends system) ────────────────────────
CREATE TABLE IF NOT EXISTS allies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  requester_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  receiver_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'blocked')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (requester_id, receiver_id)
);

CREATE INDEX IF NOT EXISTS idx_allies_requester ON allies(requester_id);
CREATE INDEX IF NOT EXISTS idx_allies_receiver ON allies(receiver_id);
CREATE INDEX IF NOT EXISTS idx_allies_status ON allies(status);

-- ── Phase 3: Districts (ward/channel categories) ────────────
CREATE TABLE IF NOT EXISTS districts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  world_id TEXT NOT NULL,
  name TEXT NOT NULL,
  position INT NOT NULL DEFAULT 0,
  UNIQUE (world_id, name)
);

CREATE INDEX IF NOT EXISTS idx_districts_world ON districts(world_id, position);

-- Add ward columns to channels (existing channels table)
DO $$ BEGIN
  ALTER TABLE channels ADD COLUMN ward_id UUID REFERENCES districts(id) ON DELETE SET NULL;
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE channels ADD COLUMN ward_name TEXT;
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;

-- Add thread columns to channel_messages (existing table)
DO $$ BEGIN
  ALTER TABLE channel_messages ADD COLUMN thread_id TEXT;
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE channel_messages ADD COLUMN thread_count INT NOT NULL DEFAULT 0;
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE channel_messages ADD COLUMN is_thread_starter BOOLEAN NOT NULL DEFAULT false;
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE channel_messages ADD COLUMN is_pinned BOOLEAN NOT NULL DEFAULT false;
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_channel_messages_thread ON channel_messages(thread_id);
CREATE INDEX IF NOT EXISTS idx_channel_messages_pinned ON channel_messages(channel_id, is_pinned);

-- RPC to increment thread count
CREATE OR REPLACE FUNCTION increment_thread_count(msg_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE channel_messages
  SET thread_count = thread_count + 1
  WHERE id = msg_id;
END;
$$ LANGUAGE plpgsql;

-- ── Phase 4: Ranks ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS world_ranks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  world_id TEXT NOT NULL,
  name TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT '#CFBCFF',
  is_hoisted BOOLEAN NOT NULL DEFAULT false,
  is_mentionable BOOLEAN NOT NULL DEFAULT false,
  position INT NOT NULL DEFAULT 0,
  edicts JSONB NOT NULL DEFAULT '{}',
  UNIQUE (world_id, name)
);

CREATE TABLE IF NOT EXISTS resident_ranks (
  resident_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rank_id UUID NOT NULL REFERENCES world_ranks(id) ON DELETE CASCADE,
  PRIMARY KEY (resident_id, rank_id)
);

CREATE INDEX IF NOT EXISTS idx_resident_ranks_resident ON resident_ranks(resident_id);
CREATE INDEX IF NOT EXISTS idx_resident_ranks_rank ON resident_ranks(rank_id);

-- ── Phase 6: FCM tokens column ──────────────────────────────
DO $$ BEGIN
  ALTER TABLE profiles ADD COLUMN fcm_token TEXT;
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;

-- ── Phase 7: Realm Audit ────────────────────────────────────
CREATE TABLE IF NOT EXISTS world_audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  world_id TEXT NOT NULL,
  actor_id TEXT,
  target_id TEXT,
  action TEXT NOT NULL,
  details JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_log_world ON world_audit_log(world_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_actor ON world_audit_log(actor_id);

-- ── SQL FUNCTION: Recalculate resident rep on changes ───────
-- NOTE: Requires a 'rep' column on profiles (not yet added — see
-- auto_join_default_channels instead for the working channel-reads pattern).
-- CREATE OR REPLACE FUNCTION recalculate_resident_rep()
-- RETURNS TRIGGER AS $$
-- BEGIN
--   UPDATE profiles
--   SET rep = (
--     SELECT COALESCE(SUM(rep), 0)
--     FROM world_members
--     WHERE resident_id = NEW.resident_id
--   )
--   WHERE id = NEW.resident_id;
--   RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- ── SQL FUNCTION: Auto-join default channels ────────────────
CREATE OR REPLACE FUNCTION auto_join_default_channels()
RETURNS TRIGGER AS $$
BEGIN
  -- Mark all default channels as read when a member joins
  INSERT INTO channel_reads (resident_id, channel_id, last_read_at)
  SELECT NEW.resident_id, c.id, now()
  FROM channels c
  WHERE c.world_id = NEW.world_id AND c.is_default = true
  ON CONFLICT (resident_id, channel_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ── Clean up orphaned data on world member removal ──────────
CREATE OR REPLACE FUNCTION cleanup_resident_on_leave()
RETURNS TRIGGER AS $$
BEGIN
  DELETE FROM resident_ranks WHERE resident_id = OLD.resident_id
    AND rank_id IN (SELECT id FROM world_ranks WHERE world_id = OLD.world_id);
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;
