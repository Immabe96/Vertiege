-- World job applications: residents apply; council/sovereign/creator can accept.

CREATE TABLE IF NOT EXISTS public.world_job_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID NOT NULL REFERENCES public.world_jobs(id) ON DELETE CASCADE,
  applicant_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  message TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'rejected', 'withdrawn')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (job_id, applicant_id)
);

CREATE INDEX IF NOT EXISTS idx_world_job_apps_job_status
  ON public.world_job_applications (job_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_world_job_apps_applicant
  ON public.world_job_applications (applicant_id, created_at DESC);

ALTER TABLE public.world_job_applications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS world_job_apps_read ON public.world_job_applications;
CREATE POLICY world_job_apps_read ON public.world_job_applications
  FOR SELECT USING (
    applicant_id = auth.uid()::text
    OR EXISTS (
      SELECT 1 FROM public.world_jobs j
      WHERE j.id = world_job_applications.job_id
        AND public.is_world_member(j.world_id)
        AND (
          j.created_by = auth.uid()::text
          OR EXISTS (
            SELECT 1 FROM public.worlds w
            WHERE w.id = j.world_id AND w.sovereign_id = auth.uid()::text
          )
          OR EXISTS (
            SELECT 1 FROM public.world_members wm
            WHERE wm.world_id = j.world_id
              AND wm.resident_id = auth.uid()::text
              AND wm.rep >= 5000
          )
        )
    )
  );

-- Standing level from world rep (mirrors lib/config/tiers.dart).
CREATE OR REPLACE FUNCTION public.world_standing_level(p_rep INT)
RETURNS INT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN COALESCE(p_rep, 0) >= 5000 THEN 7
    WHEN COALESCE(p_rep, 0) >= 1000 THEN 6
    WHEN COALESCE(p_rep, 0) >= 500 THEN 5
    WHEN COALESCE(p_rep, 0) >= 200 THEN 4
    WHEN COALESCE(p_rep, 0) >= 50 THEN 3
    WHEN COALESCE(p_rep, 0) >= 10 THEN 2
    ELSE 1
  END;
$$;

CREATE OR REPLACE FUNCTION public.apply_to_world_job(
  p_job_id UUID,
  p_message TEXT DEFAULT ''
) RETURNS public.world_job_applications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id TEXT;
  v_job public.world_jobs%ROWTYPE;
  v_rep INT;
  v_tier INT;
  v_standing INT;
  v_row public.world_job_applications%ROWTYPE;
BEGIN
  v_user_id := auth.uid()::text;
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_job FROM public.world_jobs WHERE id = p_job_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Job not found';
  END IF;
  IF v_job.status <> 'open' THEN
    RAISE EXCEPTION 'This role is no longer open';
  END IF;
  IF NOT public.is_world_member(v_job.world_id) THEN
    RAISE EXCEPTION 'You must be a world member to apply';
  END IF;

  SELECT tier INTO v_tier FROM public.profiles WHERE id = v_user_id;
  IF COALESCE(v_tier, 1) < v_job.min_tier THEN
    RAISE EXCEPTION 'Your global tier is too low for this role';
  END IF;

  SELECT rep INTO v_rep
  FROM public.world_members
  WHERE world_id = v_job.world_id AND resident_id = v_user_id;
  v_standing := public.world_standing_level(v_rep);
  IF v_standing < v_job.min_standing_level THEN
    RAISE EXCEPTION 'Your world standing is too low for this role';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.world_job_applications
    WHERE job_id = p_job_id AND applicant_id = v_user_id
      AND status IN ('pending', 'accepted')
  ) THEN
    RAISE EXCEPTION 'You already applied to this role';
  END IF;

  INSERT INTO public.world_job_applications (job_id, applicant_id, message)
  VALUES (p_job_id, v_user_id, COALESCE(NULLIF(trim(p_message), ''), ''))
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.accept_world_job_application(
  p_application_id UUID
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id TEXT;
  v_app public.world_job_applications%ROWTYPE;
  v_job public.world_jobs%ROWTYPE;
  v_can_manage BOOLEAN;
BEGIN
  v_user_id := auth.uid()::text;
  IF v_user_id IS NULL THEN RETURN FALSE; END IF;

  SELECT * INTO v_app
  FROM public.world_job_applications
  WHERE id = p_application_id;
  IF NOT FOUND OR v_app.status <> 'pending' THEN RETURN FALSE; END IF;

  SELECT * INTO v_job FROM public.world_jobs WHERE id = v_app.job_id;
  IF NOT FOUND OR v_job.status <> 'open' THEN RETURN FALSE; END IF;

  v_can_manage := (
    v_job.created_by = v_user_id
    OR EXISTS (
      SELECT 1 FROM public.worlds w
      WHERE w.id = v_job.world_id AND w.sovereign_id = v_user_id
    )
    OR EXISTS (
      SELECT 1 FROM public.world_members wm
      WHERE wm.world_id = v_job.world_id
        AND wm.resident_id = v_user_id
        AND wm.rep >= 5000
    )
  );
  IF NOT v_can_manage THEN RETURN FALSE; END IF;

  UPDATE public.world_job_applications
  SET status = 'accepted'
  WHERE id = p_application_id;

  UPDATE public.world_job_applications
  SET status = 'rejected'
  WHERE job_id = v_app.job_id
    AND id <> p_application_id
    AND status = 'pending';

  UPDATE public.world_jobs
  SET status = 'filled'
  WHERE id = v_app.job_id;

  RETURN TRUE;
END;
$$;

GRANT EXECUTE ON FUNCTION public.apply_to_world_job(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_world_job_application(UUID) TO authenticated;
