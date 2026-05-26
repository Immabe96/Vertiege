-- Unclaimed worlds: clear placeholder sovereign names; first joiner can claim.

UPDATE public.worlds
SET sovereign_name = 'Unclaimed'
WHERE (sovereign_id IS NULL OR sovereign_id = '')
  AND sovereign_name IS NOT NULL
  AND sovereign_name <> 'Unclaimed'
  AND sovereign_name <> '';

CREATE OR REPLACE FUNCTION public.claim_world_sovereignty_if_unclaimed(p_world_id TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid TEXT := auth.uid()::text;
  v_name TEXT;
BEGIN
  IF v_uid IS NULL OR p_world_id IS NULL OR length(trim(p_world_id)) = 0 THEN
    RETURN FALSE;
  END IF;

  SELECT COALESCE(NULLIF(trim(display_name), ''), NULLIF(trim(username), ''), 'Sovereign')
  INTO v_name
  FROM public.profiles
  WHERE id = v_uid;

  IF v_name IS NULL THEN
    v_name := 'Sovereign';
  END IF;

  UPDATE public.worlds
  SET sovereign_id = v_uid,
      sovereign_name = v_name
  WHERE id = p_world_id
    AND (sovereign_id IS NULL OR sovereign_id = '');

  RETURN FOUND;
END;
$$;

REVOKE ALL ON FUNCTION public.claim_world_sovereignty_if_unclaimed(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.claim_world_sovereignty_if_unclaimed(TEXT) TO authenticated;
