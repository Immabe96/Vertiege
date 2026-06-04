-- Profile label helper (no display_name column), job/rank governance RPCs.

CREATE OR REPLACE FUNCTION public.profile_public_label(p_user_id TEXT)
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT COALESCE(
    NULLIF(trim(name), ''),
    NULLIF(trim(display_title), ''),
    'Resident'
  )
  FROM public.profiles
  WHERE id = p_user_id;
$$;

GRANT EXECUTE ON FUNCTION public.profile_public_label(TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.create_listing(
  p_world_id TEXT,
  p_title TEXT,
  p_description TEXT,
  p_price TEXT,
  p_price_note TEXT,
  p_category TEXT,
  p_image_url TEXT,
  p_coin_price INT DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_listing_id UUID;
  v_seller_name TEXT;
BEGIN
  v_seller_name := public.profile_public_label(auth.uid()::text);

  INSERT INTO public.world_listings (
    world_id, seller_id, seller_name, title, description,
    price, price_note, category, image_url, coin_price
  )
  VALUES (
    p_world_id, auth.uid()::text, v_seller_name, p_title, p_description,
    p_price, p_price_note, p_category, p_image_url, p_coin_price
  )
  RETURNING id INTO v_listing_id;

  RETURN v_listing_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.claim_world_sovereignty_if_unclaimed(p_world_id TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid TEXT := auth.uid()::text;
  v_name TEXT;
BEGIN
  IF v_uid IS NULL OR p_world_id IS NULL OR length(trim(p_world_id)) = 0 THEN
    RETURN FALSE;
  END IF;

  v_name := public.profile_public_label(v_uid);
  IF v_name IS NULL OR v_name = 'Resident' THEN
    v_name := 'Sovereign';
  END IF;

  UPDATE public.worlds
  SET sovereign_id = v_uid,
      sovereign_name = v_name
  WHERE id = p_world_id
    AND (sovereign_id IS NULL OR sovereign_id = '');

  RETURN FOUND;
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

REVOKE ALL ON FUNCTION public.request_job_publish(
  TEXT, TEXT, TEXT, TEXT, INT, INT
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.request_job_publish(
  TEXT, TEXT, TEXT, TEXT, INT, INT
) TO authenticated;

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

REVOKE ALL ON FUNCTION public.request_rank_change(TEXT, TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.request_rank_change(TEXT, TEXT, TEXT, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.review_governance_proposal(
  p_proposal_id UUID,
  p_approve BOOLEAN,
  p_note TEXT DEFAULT ''
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id TEXT;
  v_row public.governance_proposals%ROWTYPE;
  v_amount INT;
  v_desc TEXT;
  v_job_id UUID;
BEGIN
  v_user_id := auth.uid()::text;
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  SELECT * INTO v_row FROM public.governance_proposals WHERE id = p_proposal_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Proposal not found');
  END IF;
  IF v_row.status <> 'pending' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Proposal already reviewed');
  END IF;
  IF NOT public.is_council_or_above(v_row.world_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Council approval required');
  END IF;

  IF NOT p_approve THEN
    UPDATE public.governance_proposals
    SET status = 'rejected',
        reviewed_by = v_user_id,
        review_note = COALESCE(p_note, ''),
        reviewed_at = now()
    WHERE id = p_proposal_id;

    INSERT INTO public.world_audit_log (world_id, actor_id, action, details)
    VALUES (
      v_row.world_id,
      v_user_id,
      'governance_proposal_rejected',
      jsonb_build_object('proposal_id', p_proposal_id, 'type', v_row.proposal_type)
    );

    RETURN jsonb_build_object('success', true, 'status', 'rejected');
  END IF;

  IF v_row.proposal_type = 'treasury_withdrawal' THEN
    v_amount := (v_row.payload->>'amount')::int;
    v_desc := COALESCE(v_row.payload->>'description', '');
    IF NOT public.withdraw_from_treasury(v_row.world_id, v_amount, v_desc) THEN
      RETURN jsonb_build_object('success', false, 'error', 'Treasury withdrawal failed');
    END IF;
  ELSIF v_row.proposal_type = 'job_publish' THEN
    INSERT INTO public.world_jobs (
      world_id, title, description, role_label,
      min_standing_level, min_tier, created_by
    ) VALUES (
      v_row.world_id,
      v_row.payload->>'title',
      COALESCE(v_row.payload->>'description', ''),
      COALESCE(v_row.payload->>'role_label', 'Contributor'),
      COALESCE((v_row.payload->>'min_standing_level')::int, 3),
      COALESCE((v_row.payload->>'min_tier')::int, 2),
      v_row.requested_by
    )
    RETURNING id INTO v_job_id;
  ELSIF v_row.proposal_type = 'rank_change' THEN
    IF COALESCE(v_row.payload->>'action', '') = 'assign' THEN
      INSERT INTO public.resident_ranks (resident_id, rank_id)
      VALUES (
        v_row.payload->>'resident_id',
        v_row.payload->>'rank_id'
      )
      ON CONFLICT (resident_id, rank_id) DO NOTHING;
    ELSIF COALESCE(v_row.payload->>'action', '') = 'remove' THEN
      DELETE FROM public.resident_ranks
      WHERE resident_id = v_row.payload->>'resident_id'
        AND rank_id = v_row.payload->>'rank_id';
    ELSE
      RETURN jsonb_build_object('success', false, 'error', 'Invalid rank action');
    END IF;
  END IF;

  UPDATE public.governance_proposals
  SET status = 'executed',
      reviewed_by = v_user_id,
      review_note = COALESCE(p_note, ''),
      reviewed_at = now()
  WHERE id = p_proposal_id;

  INSERT INTO public.world_audit_log (world_id, actor_id, action, details)
  VALUES (
    v_row.world_id,
    v_user_id,
    'governance_proposal_approved',
    jsonb_build_object('proposal_id', p_proposal_id, 'type', v_row.proposal_type)
  );

  RETURN jsonb_build_object('success', true, 'status', 'executed');
END;
$$;
