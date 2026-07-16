-- Fix touch_presence: profiles.last_seen_at is bigint epoch ms, not timestamptz.
-- S4 accidentally set last_seen_at = now(), causing PostgREST 400s.

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
    RETURN;
  END IF;

  UPDATE public.profiles
  SET last_seen_at = (extract(epoch FROM now()) * 1000)::bigint
  WHERE id = v_uid;
END;
$$;

REVOKE ALL ON FUNCTION public.touch_presence() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.touch_presence() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.touch_presence() FROM anon;

NOTIFY pgrst, 'reload schema';
