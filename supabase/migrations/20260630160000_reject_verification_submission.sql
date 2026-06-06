-- Verifier-only reject for verification_submissions (identity + profession proof).

CREATE OR REPLACE FUNCTION public.reject_verification_submission(
  p_submission_id TEXT,
  p_reviewer_notes TEXT DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_row public.verification_submissions%ROWTYPE;
  v_message TEXT;
BEGIN
  IF NOT public.is_verifier() THEN
    RAISE EXCEPTION 'Not allowed to reject verifications';
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
    status = 'rejected',
    reviewer_notes = COALESCE(
      NULLIF(trim(p_reviewer_notes), ''),
      reviewer_notes
    ),
    reviewed_by = auth.uid()::text,
    updated_at = now()
  WHERE id = v_row.id;

  v_message := COALESCE(
    NULLIF(trim(p_reviewer_notes), ''),
    'Your verification submission was not approved.'
  );

  IF public.is_identity_profession(v_row.profession) THEN
    PERFORM public._insert_achievement_notification(
      v_row.resident_id,
      'identityRejected',
      v_message
    );
  ELSE
    PERFORM public._insert_achievement_notification(
      v_row.resident_id,
      'achievementRejected',
      v_message
    );
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.reject_verification_submission(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.reject_verification_submission(TEXT, TEXT) TO authenticated;
