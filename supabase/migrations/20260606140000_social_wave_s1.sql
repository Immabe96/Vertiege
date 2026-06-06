-- Wave S1: presence heartbeat, DM read cursors, thread reply counts

-- Presence: write profiles.last_seen_at (epoch ms) for auth user
CREATE OR REPLACE FUNCTION public.touch_presence()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid TEXT;
BEGIN
  v_uid := auth.uid()::text;
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  UPDATE public.profiles
  SET last_seen_at = (extract(epoch FROM now()) * 1000)::bigint
  WHERE id = v_uid;
END;
$$;

REVOKE ALL ON FUNCTION public.touch_presence() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.touch_presence() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.touch_presence() FROM anon;

-- DM per-resident read cursor (reuses channel_reads pattern for room ids)
CREATE TABLE IF NOT EXISTS public.dm_reads (
  resident_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  room_id     TEXT NOT NULL REFERENCES public.dm_rooms(id) ON DELETE CASCADE,
  last_read_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (resident_id, room_id)
);

ALTER TABLE public.dm_reads ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS dm_reads_self ON public.dm_reads;
CREATE POLICY dm_reads_self ON public.dm_reads
  FOR ALL
  USING (resident_id = auth.uid()::text)
  WITH CHECK (resident_id = auth.uid()::text);

-- Thread replies bump parent thread_count
CREATE OR REPLACE FUNCTION public.increment_thread_count(msg_id TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  UPDATE public.channel_messages
  SET thread_count = thread_count + 1
  WHERE id = msg_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.increment_thread_count(TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.increment_thread_count(TEXT) FROM anon;

CREATE OR REPLACE FUNCTION public.on_thread_reply_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.thread_id IS NOT NULL THEN
    PERFORM public.increment_thread_count(NEW.thread_id);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS thread_reply_increment ON public.channel_messages;
CREATE TRIGGER thread_reply_increment
  AFTER INSERT ON public.channel_messages
  FOR EACH ROW
  WHEN (NEW.thread_id IS NOT NULL)
  EXECUTE FUNCTION public.on_thread_reply_insert();
