-- Wave 10/11: audit immediate governance actions; seed default season cohort challenge.

CREATE OR REPLACE FUNCTION public.seed_default_season_challenge(p_world_id TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_creator TEXT;
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.world_challenges wc
    WHERE wc.world_id = p_world_id
      AND wc.scope = 'season'
      AND wc.is_active = TRUE
  ) THEN
    RETURN;
  END IF;

  SELECT w.sovereign_id INTO v_creator
  FROM public.worlds w
  WHERE w.id = p_world_id;

  IF v_creator IS NULL OR length(trim(v_creator)) = 0 THEN
    RETURN;
  END IF;

  INSERT INTO public.world_challenges (
    world_id,
    title,
    description,
    challenge_type,
    scope,
    target_value,
    reward_xp,
    reward_currency,
    created_by
  )
  VALUES (
    p_world_id,
    'Season cohort: Rally your realm',
    'Work together this season—cohort contributions advance this shared goal.',
    'collective',
    'season',
    100,
    250,
    0,
    v_creator
  );
END;
$$;

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

  PERFORM public.seed_default_season_challenge(p_world_id);

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

CREATE OR REPLACE FUNCTION public.request_treasury_withdrawal(
  p_world_id TEXT,
  p_amount INT,
  p_description TEXT DEFAULT ''
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id TEXT;
BEGIN
  v_user_id := auth.uid()::text;
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  IF NOT public.is_council_or_above(p_world_id) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Only council or sovereign may withdraw from treasury'
    );
  END IF;
  IF public.withdraw_from_treasury(p_world_id, p_amount, p_description) THEN
    INSERT INTO public.world_audit_log (world_id, actor_id, action, details)
    VALUES (
      p_world_id,
      v_user_id,
      'governance_treasury_withdrawal',
      jsonb_build_object(
        'amount', p_amount,
        'description', COALESCE(p_description, '')
      )
    );
    RETURN jsonb_build_object('success', true, 'executed', true);
  END IF;
  RETURN jsonb_build_object('success', false, 'error', 'Withdrawal failed');
END;
$$;

CREATE OR REPLACE FUNCTION public.request_job_publish(
  p_world_id TEXT,
  p_title TEXT,
  p_description TEXT,
  p_role_label TEXT DEFAULT 'Contributor',
  p_min_standing_level INT DEFAULT 3,
  p_min_tier INT DEFAULT 2
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id TEXT;
  v_job_id UUID;
  v_proposal_id UUID;
BEGIN
  v_user_id := auth.uid()::text;
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  IF NOT public.is_world_member(p_world_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not a world member');
  END IF;
  IF p_title IS NULL OR length(trim(p_title)) = 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Title required');
  END IF;

  IF public.is_council_or_above(p_world_id)
    OR EXISTS (
      SELECT 1 FROM public.worlds w
      WHERE w.id = p_world_id AND w.sovereign_id = v_user_id
    )
    OR EXISTS (
      SELECT 1 FROM public.world_members wm
      WHERE wm.world_id = p_world_id
        AND wm.resident_id = v_user_id
        AND wm.rep >= 5000
    )
  THEN
    INSERT INTO public.world_jobs (
      world_id, title, description, role_label,
      min_standing_level, min_tier, created_by
    ) VALUES (
      p_world_id,
      trim(p_title),
      COALESCE(trim(p_description), ''),
      COALESCE(NULLIF(trim(p_role_label), ''), 'Contributor'),
      COALESCE(p_min_standing_level, 3),
      COALESCE(p_min_tier, 2),
      v_user_id
    )
    RETURNING id INTO v_job_id;

    INSERT INTO public.world_audit_log (world_id, actor_id, action, details)
    VALUES (
      p_world_id,
      v_user_id,
      'governance_job_executed',
      jsonb_build_object('job_id', v_job_id, 'title', trim(p_title))
    );

    RETURN jsonb_build_object('success', true, 'executed', true, 'job_id', v_job_id);
  END IF;

  INSERT INTO public.governance_proposals (
    world_id, proposal_type, requested_by, payload
  ) VALUES (
    p_world_id,
    'job_publish',
    v_user_id,
    jsonb_build_object(
      'title', trim(p_title),
      'description', COALESCE(trim(p_description), ''),
      'role_label', COALESCE(NULLIF(trim(p_role_label), ''), 'Contributor'),
      'min_standing_level', COALESCE(p_min_standing_level, 3),
      'min_tier', COALESCE(p_min_tier, 2)
    )
  )
  RETURNING id INTO v_proposal_id;

  RETURN jsonb_build_object(
    'success', true,
    'proposal_id', v_proposal_id,
    'status', 'pending'
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.request_rank_change(
  p_world_id TEXT,
  p_resident_id TEXT,
  p_rank_id TEXT,
  p_action TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id TEXT;
  v_proposal_id UUID;
BEGIN
  v_user_id := auth.uid()::text;
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  IF p_action NOT IN ('assign', 'remove') THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid action');
  END IF;
  IF NOT public.is_world_member(p_world_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not a world member');
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.world_ranks r
    WHERE r.id = p_rank_id AND r.world_id = p_world_id
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Unknown rank');
  END IF;

  IF public.is_council_or_above(p_world_id)
    OR EXISTS (
      SELECT 1 FROM public.worlds w
      WHERE w.id = p_world_id AND w.sovereign_id = v_user_id
    )
  THEN
    IF p_action = 'assign' THEN
      INSERT INTO public.resident_ranks (resident_id, rank_id)
      VALUES (p_resident_id, p_rank_id)
      ON CONFLICT (resident_id, rank_id) DO NOTHING;
    ELSE
      DELETE FROM public.resident_ranks
      WHERE resident_id = p_resident_id AND rank_id = p_rank_id;
    END IF;

    INSERT INTO public.world_audit_log (world_id, actor_id, action, details)
    VALUES (
      p_world_id,
      v_user_id,
      'governance_rank_change_executed',
      jsonb_build_object(
        'resident_id', p_resident_id,
        'rank_id', p_rank_id,
        'action', p_action
      )
    );

    RETURN jsonb_build_object('success', true, 'executed', true);
  END IF;

  INSERT INTO public.governance_proposals (
    world_id, proposal_type, requested_by, payload
  ) VALUES (
    p_world_id,
    'rank_change',
    v_user_id,
    jsonb_build_object(
      'resident_id', p_resident_id,
      'rank_id', p_rank_id,
      'action', p_action
    )
  )
  RETURNING id INTO v_proposal_id;

  RETURN jsonb_build_object(
    'success', true,
    'proposal_id', v_proposal_id,
    'status', 'pending'
  );
END;
$$;
