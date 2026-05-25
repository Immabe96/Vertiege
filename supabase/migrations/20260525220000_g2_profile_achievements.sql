-- G2: Public profile achievement showcase + privacy toggles.

ALTER TABLE public.user_achievements
  ADD COLUMN IF NOT EXISTS is_profile_visible BOOLEAN NOT NULL DEFAULT true;

ALTER TABLE public.user_achievements
  ADD COLUMN IF NOT EXISTS featured_order SMALLINT;

-- Residents may view others' verified, visible achievements.
DROP POLICY IF EXISTS achievements_public_profile_read ON public.user_achievements;
CREATE POLICY achievements_public_profile_read ON public.user_achievements
  FOR SELECT
  TO authenticated
  USING (
    status = 'verified'
    AND COALESCE(is_profile_visible, true) = true
    AND user_id IS DISTINCT FROM auth.uid()::text
  );

-- Owner updates visibility / featured pin.
DROP POLICY IF EXISTS achievements_self_update ON public.user_achievements;
CREATE POLICY achievements_self_update ON public.user_achievements
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid()::text)
  WITH CHECK (user_id = auth.uid()::text);
