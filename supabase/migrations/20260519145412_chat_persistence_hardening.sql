-- Harden chat persistence for direct messages and room metadata.

ALTER TABLE public.chat_messages
  ADD COLUMN IF NOT EXISTS reactions JSONB DEFAULT '{}'::jsonb;

UPDATE public.chat_messages
SET reactions = '{}'::jsonb
WHERE reactions IS NULL;

ALTER TABLE public.chat_messages
  ALTER COLUMN reactions SET DEFAULT '{}'::jsonb;

DROP POLICY IF EXISTS "dm_rooms_participant_update" ON public.dm_rooms;
CREATE POLICY "dm_rooms_participant_update" ON public.dm_rooms
  FOR UPDATE
  USING (auth.uid()::text = ANY(resident_ids))
  WITH CHECK (auth.uid()::text = ANY(resident_ids));

CREATE INDEX IF NOT EXISTS idx_chat_messages_room_created
  ON public.chat_messages(room_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_dm_rooms_last_message
  ON public.dm_rooms(last_message_at DESC);
