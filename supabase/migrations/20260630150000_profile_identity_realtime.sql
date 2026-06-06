-- Profile gamification + identity verification realtime for the mobile client.

CREATE OR REPLACE FUNCTION public.is_identity_profession(p_profession TEXT)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT p_profession IN (
    'resident-identity-passport',
    'resident-identity-national-id',
    'resident-identity'
  );
$$;

-- Verifier-only approve: marks submission verified and notifies resident for ID tick.
CREATE OR REPLACE FUNCTION public.approve_verification_submission(
  p_submission_id TEXT,
  p_reviewer_notes TEXT DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_row public.verification_submissions%ROWTYPE;
BEGIN
  IF NOT public.is_verifier() THEN
    RAISE EXCEPTION 'Not allowed to approve verifications';
  END IF;

  SELECT * INTO v_row
  FROM public.verification_submissions
  WHERE id::text = p_submission_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Verification submission not found';
  END IF;

  UPDATE public.verification_submissions
  SET
    status = 'verified',
    reviewer_notes = COALESCE(
      NULLIF(trim(p_reviewer_notes), ''),
      reviewer_notes
    ),
    reviewed_by = auth.uid()::text,
    updated_at = now()
  WHERE id = v_row.id;

  IF public.is_identity_profession(v_row.profession) THEN
    PERFORM public._insert_achievement_notification(
      v_row.resident_id,
      'identityVerified',
      'Your government ID was verified. Your resident tick is now active.'
    );
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.approve_verification_submission(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.approve_verification_submission(TEXT, TEXT) TO authenticated;

-- Realtime delivery for own profile + verification rows.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.verification_submissions;
  END IF;
EXCEPTION
  WHEN duplicate_object THEN
    NULL;
END $$;

ALTER TABLE public.profiles REPLICA IDENTITY FULL;
ALTER TABLE public.verification_submissions REPLICA IDENTITY FULL;

DROP POLICY IF EXISTS verification_self_read ON public.verification_submissions;
CREATE POLICY verification_self_read ON public.verification_submissions
  FOR SELECT
  TO authenticated
  USING (resident_id = auth.uid()::text);
