-- Wave 13: edge rate-limit bucket table + RLS hardening on cohort tables.

-- ─── Edge rate limits (service role only; used by edge functions) ───
CREATE TABLE IF NOT EXISTS public.edge_rate_limits (
  scope text NOT NULL,
  subject text NOT NULL,
  window_start timestamptz NOT NULL,
  invoke_count int NOT NULL DEFAULT 1,
  PRIMARY KEY (scope, subject, window_start)
);

ALTER TABLE public.edge_rate_limits ENABLE ROW LEVEL SECURITY;

-- No policies: authenticated/anon cannot read or write.

CREATE OR REPLACE FUNCTION public.assert_edge_rate_limit(
  p_scope text,
  p_subject text,
  p_max int,
  p_window_seconds int
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_window timestamptz;
  v_count int;
BEGIN
  IF p_max IS NULL OR p_max < 1 OR p_window_seconds IS NULL OR p_window_seconds < 1 THEN
    RAISE EXCEPTION 'invalid_rate_limit_args';
  END IF;

  v_window := to_timestamp(
    floor(extract(epoch from now()) / p_window_seconds) * p_window_seconds
  );

  INSERT INTO public.edge_rate_limits (scope, subject, window_start, invoke_count)
  VALUES (p_scope, p_subject, v_window, 1)
  ON CONFLICT (scope, subject, window_start)
  DO UPDATE SET invoke_count = public.edge_rate_limits.invoke_count + 1
  RETURNING invoke_count INTO v_count;

  IF v_count > p_max THEN
    RAISE EXCEPTION 'rate_limit_exceeded' USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.assert_edge_rate_limit(text, text, int, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.assert_edge_rate_limit(text, text, int, int) TO service_role;

-- Prune buckets older than 48h (callable from cron later).
CREATE OR REPLACE FUNCTION public.prune_edge_rate_limits()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  DELETE FROM public.edge_rate_limits
  WHERE window_start < now() - interval '48 hours';
$$;

REVOKE ALL ON FUNCTION public.prune_edge_rate_limits() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.prune_edge_rate_limits() TO service_role;

-- ─── RLS: season cohorts — no direct member writes from clients ───
DROP POLICY IF EXISTS season_cohort_members_insert ON public.season_cohort_members;
DROP POLICY IF EXISTS season_cohort_members_update ON public.season_cohort_members;
DROP POLICY IF EXISTS season_cohort_members_delete ON public.season_cohort_members;

DROP POLICY IF EXISTS season_cohorts_insert ON public.season_cohorts;
DROP POLICY IF EXISTS season_cohorts_update ON public.season_cohorts;
DROP POLICY IF EXISTS season_cohorts_delete ON public.season_cohorts;
