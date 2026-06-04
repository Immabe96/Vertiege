-- Wave 8/11: server-side poll creation; Season 1 cohort membership per world.

CREATE OR REPLACE FUNCTION public.create_world_poll(
  p_world_id TEXT,
  p_question TEXT,
  p_options JSONB,
  p_channel_id TEXT DEFAULT NULL,
  p_expires_at BIGINT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id TEXT;
  v_poll public.world_polls%ROWTYPE;
  v_opt_count INT;
BEGIN
  v_user_id := auth.uid()::text;
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  IF p_question IS NULL OR length(trim(p_question)) < 3 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Question must be at least 3 characters');
  END IF;

  IF p_options IS NULL OR jsonb_typeof(p_options) <> 'array' THEN
    RETURN jsonb_build_object('success', false, 'error', 'At least two options required');
  END IF;

  SELECT count(*) INTO v_opt_count
  FROM jsonb_array_elements_text(p_options) AS opt
  WHERE length(trim(opt)) > 0;

  IF v_opt_count < 2 THEN
    RETURN jsonb_build_object('success', false, 'error', 'At least two options required');
  END IF;
  IF v_opt_count > 6 THEN
    RETURN jsonb_build_object('success', false, 'error', 'At most six options allowed');
  END IF;

  IF NOT public.is_world_member(p_world_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not a member of this world');
  END IF;

  IF NOT public.can_create_world_poll(p_world_id) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Polls require Veteran standing or council in this world'
    );
  END IF;

  INSERT INTO public.world_polls (
    world_id,
    channel_id,
    question,
    options,
    results,
    created_by,
    expires_at
  )
  VALUES (
    p_world_id,
    p_channel_id,
    trim(p_question),
    p_options,
    '{}'::jsonb,
    v_user_id,
    p_expires_at
  )
  RETURNING * INTO v_poll;

  RETURN jsonb_build_object('success', true, 'poll', to_jsonb(v_poll));
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

REVOKE ALL ON FUNCTION public.create_world_poll(TEXT, TEXT, JSONB, TEXT, BIGINT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_world_poll(TEXT, TEXT, JSONB, TEXT, BIGINT) TO authenticated;

-- ─── Season cohorts (one cohort per world per active global season) ───
CREATE TABLE IF NOT EXISTS public.season_cohorts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  season_id TEXT NOT NULL REFERENCES public.global_seasons(id) ON DELETE CASCADE,
  world_id TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (season_id, world_id)
);

CREATE TABLE IF NOT EXISTS public.season_cohort_members (
  cohort_id UUID NOT NULL REFERENCES public.season_cohorts(id) ON DELETE CASCADE,
  resident_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (cohort_id, resident_id)
);

CREATE INDEX IF NOT EXISTS idx_season_cohort_members_resident
  ON public.season_cohort_members (resident_id);

ALTER TABLE public.season_cohorts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.season_cohort_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS season_cohorts_read ON public.season_cohorts;
CREATE POLICY season_cohorts_read ON public.season_cohorts
  FOR SELECT USING (public.is_world_member(world_id));

DROP POLICY IF EXISTS season_cohort_members_read ON public.season_cohort_members;
CREATE POLICY season_cohort_members_read ON public.season_cohort_members
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.season_cohorts sc
      WHERE sc.id = cohort_id
        AND public.is_world_member(sc.world_id)
    )
  );

CREATE OR REPLACE FUNCTION public.ensure_season_cohort_membership(p_world_id TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id TEXT;
  v_season_id TEXT;
  v_world_name TEXT;
  v_cohort_id UUID;
  v_member_count INT;
BEGIN
  v_user_id := auth.uid()::text;
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  IF NOT public.is_world_member(p_world_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not a member of this world');
  END IF;

  SELECT id INTO v_season_id
  FROM public.global_seasons
  WHERE is_active = true
  ORDER BY starts_at DESC
  LIMIT 1;

  IF v_season_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'No active season');
  END IF;

  SELECT name INTO v_world_name FROM public.worlds WHERE id = p_world_id;
  IF v_world_name IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'World not found');
  END IF;

  INSERT INTO public.season_cohorts (season_id, world_id, display_name)
  VALUES (v_season_id, p_world_id, v_world_name || ' cohort')
  ON CONFLICT (season_id, world_id) DO UPDATE
  SET display_name = EXCLUDED.display_name
  RETURNING id INTO v_cohort_id;

  INSERT INTO public.season_cohort_members (cohort_id, resident_id)
  VALUES (v_cohort_id, v_user_id)
  ON CONFLICT DO NOTHING;

  SELECT count(*)::int INTO v_member_count
  FROM public.season_cohort_members
  WHERE cohort_id = v_cohort_id;

  RETURN jsonb_build_object(
    'success', true,
    'cohort_id', v_cohort_id,
    'season_id', v_season_id,
    'world_id', p_world_id,
    'display_name', v_world_name || ' cohort',
    'member_count', v_member_count
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_season_cohort_summary(p_world_id TEXT)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_season_id TEXT;
  v_row RECORD;
  v_member_count INT;
BEGIN
  SELECT id INTO v_season_id
  FROM public.global_seasons
  WHERE is_active = true
  ORDER BY starts_at DESC
  LIMIT 1;

  IF v_season_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'No active season');
  END IF;

  SELECT sc.id, sc.display_name, sc.season_id
  INTO v_row
  FROM public.season_cohorts sc
  WHERE sc.season_id = v_season_id AND sc.world_id = p_world_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', true, 'cohort', NULL);
  END IF;

  SELECT count(*)::int INTO v_member_count
  FROM public.season_cohort_members
  WHERE cohort_id = v_row.id;

  RETURN jsonb_build_object(
    'success', true,
    'cohort', jsonb_build_object(
      'id', v_row.id,
      'season_id', v_row.season_id,
      'world_id', p_world_id,
      'display_name', v_row.display_name,
      'member_count', v_member_count
    )
  );
END;
$$;

REVOKE ALL ON FUNCTION public.ensure_season_cohort_membership(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.ensure_season_cohort_membership(TEXT) TO authenticated;
REVOKE ALL ON FUNCTION public.get_season_cohort_summary(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_season_cohort_summary(TEXT) TO authenticated;
