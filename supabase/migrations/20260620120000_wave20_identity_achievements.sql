-- Wave 20: achievement stories, featured ids as text, verifier queue metrics.

-- Featured achievements use catalog text ids (not UUID).
DROP FUNCTION IF EXISTS public.set_featured_achievements(UUID[]);

ALTER TABLE public.profiles
  DROP COLUMN IF EXISTS featured_achievement_ids;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS featured_achievement_ids TEXT[] NOT NULL DEFAULT '{}';

CREATE OR REPLACE FUNCTION public.set_featured_achievements(p_ids TEXT[])
RETURNS TEXT[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid TEXT;
  v_trimmed TEXT[];
BEGIN
  v_uid := auth.uid()::text;
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT COALESCE(array_agg(x ORDER BY ord), '{}'::text[])
  INTO v_trimmed
  FROM (
    SELECT x, row_number() OVER () AS ord
    FROM unnest(COALESCE(p_ids, '{}'::text[])) AS x
    WHERE length(trim(x)) > 0
    LIMIT 3
  ) s;

  UPDATE public.profiles
  SET featured_achievement_ids = v_trimmed
  WHERE id = v_uid;

  RETURN v_trimmed;
END;
$$;

GRANT EXECUTE ON FUNCTION public.set_featured_achievements(TEXT[]) TO authenticated;

-- Optional story on verified achievements (moderated at verify time).
ALTER TABLE public.user_achievements
  ADD COLUMN IF NOT EXISTS achievement_story TEXT;

COMMENT ON COLUMN public.user_achievements.achievement_story IS
  'Optional resident narrative shown on public profile when verified.';

-- Verifier queue metrics for SLA dashboard.
CREATE OR REPLACE FUNCTION public.get_verifier_queue_metrics()
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  WITH pending AS (
    SELECT submitted_at
    FROM public.user_achievements
    WHERE status = 'submitted'
      AND submitted_at IS NOT NULL
  ),
  recent AS (
    SELECT
      extract(epoch from (verified_at - submitted_at)) / 3600.0 AS hours_to_verify
    FROM public.user_achievements
    WHERE status = 'verified'
      AND submitted_at IS NOT NULL
      AND verified_at IS NOT NULL
      AND verified_at > now() - interval '30 days'
  )
  SELECT jsonb_build_object(
    'pending_count', (SELECT count(*)::int FROM pending),
    'median_hours_pending',
      COALESCE(
        (SELECT percentile_cont(0.5) WITHIN GROUP (
          ORDER BY extract(epoch from (now() - submitted_at)) / 3600.0
        ) FROM pending),
        0
      ),
    'median_hours_to_verify',
      COALESCE(
        (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY hours_to_verify) FROM recent),
        0
      )
  );
$$;

REVOKE ALL ON FUNCTION public.get_verifier_queue_metrics() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_verifier_queue_metrics() TO authenticated;
