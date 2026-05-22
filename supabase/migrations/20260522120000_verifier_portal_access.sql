-- Verifier portal: staff can read/update all profession verification submissions.

CREATE OR REPLACE FUNCTION public.is_verifier()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
  SELECT COALESCE((auth.jwt() -> 'app_metadata' ->> 'is_verifier')::boolean, false)
    OR COALESCE((auth.jwt() -> 'app_metadata' ->> 'role') = 'verifier', false);
$$;

REVOKE ALL ON FUNCTION public.is_verifier() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_verifier() TO authenticated;

DROP POLICY IF EXISTS verification_verifier_read ON public.verification_submissions;
CREATE POLICY verification_verifier_read ON public.verification_submissions
  FOR SELECT
  TO authenticated
  USING (public.is_verifier());

DROP POLICY IF EXISTS verification_verifier_update ON public.verification_submissions;
CREATE POLICY verification_verifier_update ON public.verification_submissions
  FOR UPDATE
  TO authenticated
  USING (public.is_verifier())
  WITH CHECK (public.is_verifier());

-- Grant verifier flag to owner account (same credentials as superuser; use /verifier/login).
UPDATE auth.users
SET raw_app_meta_data = COALESCE(raw_app_meta_data, '{}'::jsonb) ||
  jsonb_build_object('is_verifier', true, 'role', 'verifier')
WHERE lower(email) = lower('ltyl.naughty@gmail.com');
