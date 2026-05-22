-- Verifiers can review submitted achievement proofs.

DROP POLICY IF EXISTS achievements_verifier_read ON public.user_achievements;
CREATE POLICY achievements_verifier_read ON public.user_achievements
  FOR SELECT
  TO authenticated
  USING (public.is_verifier());

DROP POLICY IF EXISTS achievements_verifier_update ON public.user_achievements;
CREATE POLICY achievements_verifier_update ON public.user_achievements
  FOR UPDATE
  TO authenticated
  USING (public.is_verifier())
  WITH CHECK (public.is_verifier());
