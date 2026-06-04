-- Wave 17: notify applicants when world job applications are accepted or rejected.

CREATE OR REPLACE FUNCTION public.reject_world_job_application(p_application_id UUID)
RETURNS BOOLEAN
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
  IF NOT FOUND THEN RETURN FALSE; END IF;

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
  SET status = 'rejected'
  WHERE id = p_application_id;

  RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION public.trg_world_job_application_status_notify()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_title TEXT;
  v_msg TEXT;
  v_type TEXT;
BEGIN
  IF TG_OP <> 'UPDATE' THEN RETURN NEW; END IF;
  IF OLD.status IS NOT DISTINCT FROM NEW.status THEN RETURN NEW; END IF;
  IF NEW.status NOT IN ('accepted', 'rejected') THEN RETURN NEW; END IF;

  SELECT title INTO v_title FROM public.world_jobs WHERE id = NEW.job_id;
  v_title := COALESCE(NULLIF(trim(v_title), ''), 'a world role');

  IF NEW.status = 'accepted' THEN
    v_type := 'jobApplicationAccepted';
    v_msg := 'Your application for "' || v_title || '" was accepted.';
  ELSE
    v_type := 'jobApplicationRejected';
    v_msg := 'Your application for "' || v_title || '" was not selected this time.';
  END IF;

  INSERT INTO public.notifications (
    id,
    recipient_id,
    type,
    message,
    world_id,
    read,
    created_at
  )
  SELECT
    gen_random_uuid()::text,
    NEW.applicant_id,
    v_type,
    left(v_msg, 500),
    j.world_id,
    false,
    now()
  FROM public.world_jobs j
  WHERE j.id = NEW.job_id;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS world_job_application_status_notify ON public.world_job_applications;
CREATE TRIGGER world_job_application_status_notify
  AFTER UPDATE OF status ON public.world_job_applications
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_world_job_application_status_notify();

GRANT EXECUTE ON FUNCTION public.reject_world_job_application(UUID) TO authenticated;
