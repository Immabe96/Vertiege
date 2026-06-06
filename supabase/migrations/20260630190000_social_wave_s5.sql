-- Wave S5: per-resident channel mentions, notifications channel_id, active residents RPC.

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS channel_id TEXT REFERENCES public.channels(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_notifications_channel_id
  ON public.notifications(channel_id)
  WHERE channel_id IS NOT NULL;

-- Fan-out mention notifications for @Handle matches (world_members.resident_name).
CREATE OR REPLACE FUNCTION public.broadcast_channel_mention_notifications(
  p_world_id TEXT,
  p_channel_id TEXT,
  p_sender_id TEXT,
  p_mention_handles TEXT[],
  p_message TEXT
) RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid TEXT;
  v_count INT := 0;
  v_handle TEXT;
  v_member RECORD;
BEGIN
  v_uid := auth.uid()::text;
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF p_sender_id IS DISTINCT FROM v_uid THEN
    RAISE EXCEPTION 'Sender must match authenticated user';
  END IF;
  IF p_world_id IS NULL OR length(trim(p_world_id)) = 0 THEN
    RETURN 0;
  END IF;
  IF p_mention_handles IS NULL OR array_length(p_mention_handles, 1) IS NULL THEN
    RETURN 0;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.world_members wm
    WHERE wm.world_id = p_world_id AND wm.resident_id = v_uid
  ) THEN
    RAISE EXCEPTION 'Not a member of this world';
  END IF;

  FOREACH v_handle IN ARRAY p_mention_handles LOOP
    IF v_handle IS NULL OR length(trim(v_handle)) = 0 THEN
      CONTINUE;
    END IF;
    IF lower(trim(v_handle)) IN ('allresidents', 'everyone', 'here') THEN
      CONTINUE;
    END IF;

    FOR v_member IN
      SELECT wm.resident_id
      FROM public.world_members wm
      WHERE wm.world_id = p_world_id
        AND wm.resident_id IS DISTINCT FROM p_sender_id
        AND lower(regexp_replace(coalesce(wm.resident_name, ''), '[^a-zA-Z0-9]', '', 'g'))
            = lower(regexp_replace(trim(v_handle), '[^a-zA-Z0-9]', '', 'g'))
    LOOP
      INSERT INTO public.notifications (
        id,
        recipient_id,
        type,
        message,
        world_id,
        channel_id,
        read,
        created_at
      ) VALUES (
        gen_random_uuid()::text,
        v_member.resident_id,
        'mention',
        coalesce(nullif(trim(p_message), ''), 'Someone mentioned you'),
        p_world_id,
        p_channel_id,
        false,
        now()
      );
      v_count := v_count + 1;
    END LOOP;
  END LOOP;

  RETURN v_count;
END;
$$;

REVOKE ALL ON FUNCTION public.broadcast_channel_mention_notifications(TEXT, TEXT, TEXT, TEXT[], TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.broadcast_channel_mention_notifications(TEXT, TEXT, TEXT, TEXT[], TEXT) TO authenticated;

-- Normalize profiles.last_seen_at (bigint ms/sec or timestamptz) to epoch seconds.
CREATE OR REPLACE FUNCTION public.profile_last_seen_epoch(p_last_seen_at ANYELEMENT)
RETURNS DOUBLE PRECISION
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_kind TEXT;
BEGIN
  IF p_last_seen_at IS NULL THEN
    RETURN NULL;
  END IF;
  v_kind := pg_typeof(p_last_seen_at)::text;
  IF v_kind = 'bigint' OR v_kind = 'integer' THEN
    IF p_last_seen_at::bigint > 1000000000000 THEN
      RETURN p_last_seen_at::double precision / 1000.0;
    END IF;
    RETURN p_last_seen_at::double precision;
  END IF;
  RETURN extract(epoch FROM p_last_seen_at::timestamptz);
END;
$$;

-- Online residents for world activity preview (last_seen_at within idle window).
CREATE OR REPLACE FUNCTION public.list_world_active_residents(
  p_world_id TEXT,
  p_limit INT DEFAULT 5
) RETURNS TABLE (
  resident_id TEXT,
  resident_name TEXT,
  avatar_url TEXT,
  last_seen_at BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT
    wm.resident_id,
    wm.resident_name,
    p.avatar_url,
    p.last_seen_at::bigint
  FROM public.world_members wm
  JOIN public.profiles p ON p.id = wm.resident_id
  WHERE wm.world_id = p_world_id
    AND p.last_seen_at IS NOT NULL
    AND public.profile_last_seen_epoch(p.last_seen_at)
      > extract(epoch FROM now() - interval '15 minutes')
    AND coalesce(p.presence_mode, 'online') <> 'invisible'
  ORDER BY public.profile_last_seen_epoch(p.last_seen_at) DESC
  LIMIT greatest(1, least(coalesce(p_limit, 5), 12));
$$;

REVOKE ALL ON FUNCTION public.list_world_active_residents(TEXT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_world_active_residents(TEXT, INT) TO authenticated;
