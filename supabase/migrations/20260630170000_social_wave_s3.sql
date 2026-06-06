-- Wave S3: DM read receipts, channel mute prefs, dm_reads backfill table.

-- DM room read cursors (used by client unread + read receipts).
CREATE TABLE IF NOT EXISTS public.dm_reads (
  resident_id   TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  room_id       TEXT NOT NULL REFERENCES public.dm_rooms(id) ON DELETE CASCADE,
  last_read_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (resident_id, room_id)
);

ALTER TABLE public.dm_reads ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS dm_reads_self ON public.dm_reads;
CREATE POLICY dm_reads_self ON public.dm_reads
  FOR ALL
  USING (resident_id = auth.uid()::text)
  WITH CHECK (resident_id = auth.uid()::text);

DROP POLICY IF EXISTS dm_reads_room_participant_read ON public.dm_reads;
CREATE POLICY dm_reads_room_participant_read ON public.dm_reads
  FOR SELECT
  USING (public.is_dm_participant(room_id));

CREATE INDEX IF NOT EXISTS idx_dm_reads_room ON public.dm_reads(room_id);

-- Per-message read receipts (DMs only).
CREATE TABLE IF NOT EXISTS public.message_reads (
  message_id   TEXT NOT NULL REFERENCES public.chat_messages(id) ON DELETE CASCADE,
  resident_id  TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  room_id      TEXT NOT NULL REFERENCES public.dm_rooms(id) ON DELETE CASCADE,
  read_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (message_id, resident_id)
);

ALTER TABLE public.message_reads ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS message_reads_self_write ON public.message_reads;
CREATE POLICY message_reads_self_write ON public.message_reads
  FOR ALL
  USING (resident_id = auth.uid()::text)
  WITH CHECK (
    resident_id = auth.uid()::text
    AND public.is_dm_participant(room_id)
  );

DROP POLICY IF EXISTS message_reads_participant_read ON public.message_reads;
CREATE POLICY message_reads_participant_read ON public.message_reads
  FOR SELECT
  USING (public.is_dm_participant(room_id));

CREATE INDEX IF NOT EXISTS idx_message_reads_room ON public.message_reads(room_id, resident_id);

-- Per-channel notification overrides.
CREATE TABLE IF NOT EXISTS public.channel_mute_prefs (
  resident_id  TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  channel_id   TEXT NOT NULL REFERENCES public.channels(id) ON DELETE CASCADE,
  mute_mode    TEXT NOT NULL DEFAULT 'all'
    CHECK (mute_mode IN ('all', 'mentions_only', 'off')),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (resident_id, channel_id)
);

ALTER TABLE public.channel_mute_prefs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS channel_mute_prefs_self ON public.channel_mute_prefs;
CREATE POLICY channel_mute_prefs_self ON public.channel_mute_prefs
  FOR ALL
  USING (resident_id = auth.uid()::text)
  WITH CHECK (resident_id = auth.uid()::text);

CREATE INDEX IF NOT EXISTS idx_channel_mute_prefs_channel
  ON public.channel_mute_prefs(channel_id);
