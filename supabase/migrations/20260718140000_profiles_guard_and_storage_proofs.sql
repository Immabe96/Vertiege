-- Corrective: attach profiles privilege guard + drop overly broad verification-proofs reads.

DROP TRIGGER IF EXISTS profiles_guard_privileged_columns ON public.profiles;
CREATE TRIGGER profiles_guard_privileged_columns
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.profiles_guard_privileged_columns();

-- Any authenticated user could previously SELECT all verification proofs.
DROP POLICY IF EXISTS "Authenticated users can read verification proofs" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated can read verification proofs" ON storage.objects;
DROP POLICY IF EXISTS verification_proofs_read ON storage.objects;
DROP POLICY IF EXISTS verification_proofs_select ON storage.objects;

-- Keep owner + verifier SELECT (recreate if missing from prior lockdown).
DROP POLICY IF EXISTS verification_proofs_owner_select ON storage.objects;
CREATE POLICY verification_proofs_owner_select ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'verification-proofs'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS verification_proofs_verifier_select ON storage.objects;
CREATE POLICY verification_proofs_verifier_select ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'verification-proofs'
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()::text
        AND (
          p.verified_roles @> ARRAY['verifier']::text[]
          OR p.verified_roles @> ARRAY['super_admin']::text[]
        )
    )
  );
