-- Durable RSVPs on event-style posts + columns already selected by the client.

ALTER TABLE public.posts
  ADD COLUMN IF NOT EXISTS event_rsvp_ids TEXT[] NOT NULL DEFAULT '{}'::text[],
  ADD COLUMN IF NOT EXISTS event_title TEXT,
  ADD COLUMN IF NOT EXISTS event_starts_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS awards JSONB NOT NULL DEFAULT '[]'::jsonb;

CREATE OR REPLACE FUNCTION public.toggle_post_event_rsvp(p_post_id TEXT)
RETURNS TEXT[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid TEXT;
  v_world TEXT;
  v_ids TEXT[];
BEGIN
  v_uid := auth.uid()::text;
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF p_post_id IS NULL OR length(trim(p_post_id)) = 0 THEN
    RAISE EXCEPTION 'post_id required';
  END IF;

  SELECT world_id, COALESCE(event_rsvp_ids, '{}'::text[])
    INTO v_world, v_ids
  FROM public.posts
  WHERE id = p_post_id
    AND deleted_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Post not found';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.world_members
    WHERE world_id = v_world AND resident_id = v_uid
  ) THEN
    RAISE EXCEPTION 'Not a world member';
  END IF;

  IF v_uid = ANY (v_ids) THEN
    v_ids := array_remove(v_ids, v_uid);
  ELSE
    v_ids := array_append(v_ids, v_uid);
  END IF;

  UPDATE public.posts
  SET event_rsvp_ids = v_ids, updated_at = now()
  WHERE id = p_post_id;

  RETURN v_ids;
END;
$$;

REVOKE ALL ON FUNCTION public.toggle_post_event_rsvp(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.toggle_post_event_rsvp(TEXT) TO authenticated;
