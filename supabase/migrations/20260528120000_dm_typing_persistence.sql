-- Hybrid DM typing: short-lived rows for on-open / multi-device + Realtime fanout.

CREATE TABLE IF NOT EXISTS public.dm_typing (
  room_id    TEXT NOT NULL REFERENCES public.dm_rooms(id) ON DELETE CASCADE,
  user_id    TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (room_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_dm_typing_room_updated
  ON public.dm_typing(room_id, updated_at DESC);

ALTER TABLE public.dm_typing ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "dm_typing_participant_read" ON public.dm_typing;
CREATE POLICY "dm_typing_participant_read" ON public.dm_typing
  FOR SELECT
  USING (public.is_dm_participant(room_id));

DROP POLICY IF EXISTS "dm_typing_self_insert" ON public.dm_typing;
CREATE POLICY "dm_typing_self_insert" ON public.dm_typing
  FOR INSERT
  WITH CHECK (
    user_id = auth.uid()::text
    AND public.is_dm_participant(room_id)
  );

DROP POLICY IF EXISTS "dm_typing_self_update" ON public.dm_typing;
CREATE POLICY "dm_typing_self_update" ON public.dm_typing
  FOR UPDATE
  USING (user_id = auth.uid()::text AND public.is_dm_participant(room_id))
  WITH CHECK (user_id = auth.uid()::text AND public.is_dm_participant(room_id));

DROP POLICY IF EXISTS "dm_typing_self_delete" ON public.dm_typing;
CREATE POLICY "dm_typing_self_delete" ON public.dm_typing
  FOR DELETE
  USING (user_id = auth.uid()::text);

-- Upsert / clear via RPC (participant check + auth).
CREATE OR REPLACE FUNCTION public.upsert_dm_typing(p_room_id TEXT, p_is_typing BOOLEAN)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid TEXT := auth.uid()::text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  IF NOT public.is_dm_participant(p_room_id) THEN
    RAISE EXCEPTION 'not a dm participant';
  END IF;

  IF NOT p_is_typing THEN
    DELETE FROM public.dm_typing
    WHERE room_id = p_room_id AND user_id = v_uid;
    RETURN;
  END IF;

  INSERT INTO public.dm_typing (room_id, user_id, updated_at)
  VALUES (p_room_id, v_uid, now())
  ON CONFLICT (room_id, user_id)
  DO UPDATE SET updated_at = EXCLUDED.updated_at;
END;
$$;

REVOKE ALL ON FUNCTION public.upsert_dm_typing(TEXT, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.upsert_dm_typing(TEXT, BOOLEAN) TO authenticated;

-- Prune stale rows (optional manual/cron); safe to call from clients too.
CREATE OR REPLACE FUNCTION public.prune_dm_typing(p_room_id TEXT DEFAULT NULL)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_deleted INTEGER;
BEGIN
  DELETE FROM public.dm_typing
  WHERE updated_at < now() - interval '30 seconds'
    AND (p_room_id IS NULL OR room_id = p_room_id);
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END;
$$;

REVOKE ALL ON FUNCTION public.prune_dm_typing(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.prune_dm_typing(TEXT) TO authenticated;

-- Realtime: postgres_changes on dm_typing for live sync when broadcast misses.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.dm_typing;
  END IF;
EXCEPTION
  WHEN duplicate_object THEN
    NULL;
END $$;
