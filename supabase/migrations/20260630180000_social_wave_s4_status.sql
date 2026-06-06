-- Wave S4: persisted resident status + touch_presence RPC.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS presence_mode TEXT NOT NULL DEFAULT 'online'
    CHECK (presence_mode IN ('online', 'idle', 'dnd', 'invisible'));

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS custom_status TEXT;

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
  IF v_uid IS NULL THEN RETURN; END IF;
  UPDATE public.profiles
  SET last_seen_at = now()
  WHERE id = v_uid;
END;
$$;

CREATE OR REPLACE FUNCTION public.upsert_resident_status(
  p_presence_mode TEXT DEFAULT NULL,
  p_custom_status TEXT DEFAULT NULL
)
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

  IF p_presence_mode IS NOT NULL
     AND p_presence_mode NOT IN ('online', 'idle', 'dnd', 'invisible') THEN
    RAISE EXCEPTION 'Invalid presence mode';
  END IF;

  UPDATE public.profiles
  SET
    presence_mode = COALESCE(p_presence_mode, presence_mode),
    custom_status = CASE
      WHEN p_custom_status IS NULL THEN custom_status
      WHEN length(trim(p_custom_status)) = 0 THEN NULL
      ELSE left(trim(p_custom_status), 60)
    END,
    last_seen_at = now()
  WHERE id = v_uid;
END;
$$;

GRANT EXECUTE ON FUNCTION public.touch_presence() TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_resident_status(TEXT, TEXT) TO authenticated;
