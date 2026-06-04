-- Wave 19: voice presence, governance notifications, poll moderation, coin packs.

-- ─── Voice channel occupancy (heartbeat) ───
CREATE TABLE IF NOT EXISTS public.voice_channel_presence (
  channel_id TEXT NOT NULL,
  world_id TEXT NOT NULL,
  resident_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (channel_id, resident_id)
);

CREATE INDEX IF NOT EXISTS idx_voice_presence_channel_seen
  ON public.voice_channel_presence (channel_id, last_seen_at DESC);

ALTER TABLE public.voice_channel_presence ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS voice_presence_read ON public.voice_channel_presence;
CREATE POLICY voice_presence_read ON public.voice_channel_presence
  FOR SELECT USING (true);

DROP POLICY IF EXISTS voice_presence_upsert ON public.voice_channel_presence;
CREATE POLICY voice_presence_upsert ON public.voice_channel_presence
  FOR ALL USING (resident_id = auth.uid()::text)
  WITH CHECK (resident_id = auth.uid()::text);

CREATE OR REPLACE FUNCTION public.heartbeat_voice_presence(
  p_channel_id TEXT,
  p_world_id TEXT
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid TEXT;
BEGIN
  v_uid := auth.uid()::text;
  IF v_uid IS NULL OR p_channel_id IS NULL OR p_world_id IS NULL THEN RETURN 0; END IF;
  IF NOT public.is_world_member(p_world_id) THEN RETURN 0; END IF;

  INSERT INTO public.voice_channel_presence (channel_id, world_id, resident_id, last_seen_at)
  VALUES (p_channel_id, p_world_id, v_uid, now())
  ON CONFLICT (channel_id, resident_id) DO UPDATE
  SET last_seen_at = now(), world_id = EXCLUDED.world_id;

  DELETE FROM public.voice_channel_presence
  WHERE channel_id = p_channel_id
    AND last_seen_at < now() - interval '2 minutes';

  RETURN (
    SELECT count(*)::int FROM public.voice_channel_presence
    WHERE channel_id = p_channel_id
      AND last_seen_at > now() - interval '90 seconds'
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.heartbeat_voice_presence(TEXT, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_voice_channel_occupancy(p_channel_id TEXT)
RETURNS INT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT count(*)::int
  FROM public.voice_channel_presence
  WHERE channel_id = p_channel_id
    AND last_seen_at > now() - interval '90 seconds';
$$;

GRANT EXECUTE ON FUNCTION public.get_voice_channel_occupancy(TEXT) TO authenticated;

-- ─── Coin pack IAP grants ───
CREATE TABLE IF NOT EXISTS public.coin_pack_redemptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resident_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL,
  purchase_token TEXT NOT NULL UNIQUE,
  coins_granted INT NOT NULL,
  platform TEXT NOT NULL DEFAULT 'unknown',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_coin_pack_redemptions_resident
  ON public.coin_pack_redemptions (resident_id, created_at DESC);

ALTER TABLE public.coin_pack_redemptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS coin_pack_redemptions_self_read ON public.coin_pack_redemptions;
CREATE POLICY coin_pack_redemptions_self_read ON public.coin_pack_redemptions
  FOR SELECT USING (resident_id = auth.uid()::text);

CREATE OR REPLACE FUNCTION public.grant_coin_pack_purchase(
  p_product_id TEXT,
  p_purchase_token TEXT,
  p_platform TEXT DEFAULT 'unknown'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid TEXT;
  v_coins INT;
  v_token TEXT;
  v_balance INT;
BEGIN
  v_uid := auth.uid()::text;
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  v_token := trim(p_purchase_token);
  IF v_token IS NULL OR length(v_token) < 8 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid purchase token');
  END IF;

  v_coins := CASE p_product_id
    WHEN 'coin_pack_starter' THEN 100
    WHEN 'coin_pack_value' THEN 550
    WHEN 'coin_pack_elite' THEN 1200
    ELSE NULL
  END;

  IF v_coins IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Unknown coin pack');
  END IF;

  IF EXISTS (SELECT 1 FROM public.coin_pack_redemptions WHERE purchase_token = v_token) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Purchase already redeemed');
  END IF;

  INSERT INTO public.coin_pack_redemptions (
    resident_id, product_id, purchase_token, coins_granted, platform
  )
  VALUES (
    v_uid, p_product_id, v_token, v_coins, coalesce(nullif(trim(p_platform), ''), 'unknown')
  );

  UPDATE public.profiles
  SET sovereign_coins = sovereign_coins + v_coins
  WHERE id = v_uid
  RETURNING sovereign_coins INTO v_balance;

  INSERT INTO public.coin_transactions (resident_id, amount, reason, balance_after)
  VALUES (v_uid, v_coins, 'coin_pack:' || p_product_id, v_balance);

  RETURN jsonb_build_object('success', true, 'coins', v_coins, 'balance', v_balance);
END;
$$;

GRANT EXECUTE ON FUNCTION public.grant_coin_pack_purchase(TEXT, TEXT, TEXT) TO authenticated;

-- ─── Poll moderation (council) ───
CREATE OR REPLACE FUNCTION public.moderate_world_poll(
  p_poll_id UUID,
  p_action TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid TEXT;
  v_poll public.world_polls%ROWTYPE;
  v_action TEXT;
BEGIN
  v_uid := auth.uid()::text;
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  v_action := lower(trim(coalesce(p_action, '')));
  IF v_action NOT IN ('close', 'delete') THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid action');
  END IF;

  SELECT * INTO v_poll FROM public.world_polls WHERE id = p_poll_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Poll not found');
  END IF;

  IF NOT public.is_council_or_above(v_poll.world_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Council permission required');
  END IF;

  IF v_action = 'close' THEN
    UPDATE public.world_polls
    SET is_closed = true
    WHERE id = p_poll_id;
  ELSE
    DELETE FROM public.world_polls WHERE id = p_poll_id;
  END IF;

  INSERT INTO public.world_audit_log (world_id, actor_id, action, details)
  VALUES (
    v_poll.world_id,
    v_uid,
    'poll_moderated',
    jsonb_build_object('poll_id', p_poll_id, 'moderation_action', v_action)
  );

  RETURN jsonb_build_object('success', true, 'action', v_action);
END;
$$;

GRANT EXECUTE ON FUNCTION public.moderate_world_poll(UUID, TEXT) TO authenticated;

-- ─── Treasury proposed vs executed audit (restore member proposals) ───
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
  v_proposal_id UUID;
BEGIN
  v_user_id := auth.uid()::text;
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  IF p_amount IS NULL OR p_amount <= 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid amount');
  END IF;
  IF NOT public.is_world_member(p_world_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not a world member');
  END IF;

  IF public.is_council_or_above(p_world_id) THEN
    IF public.withdraw_from_treasury(p_world_id, p_amount, p_description) THEN
      INSERT INTO public.world_audit_log (world_id, actor_id, action, details)
      VALUES (
        p_world_id,
        v_user_id,
        'governance_treasury_executed',
        jsonb_build_object(
          'amount', p_amount,
          'description', COALESCE(p_description, ''),
          'status', 'executed'
        )
      );
      RETURN jsonb_build_object('success', true, 'executed', true);
    END IF;
    RETURN jsonb_build_object('success', false, 'error', 'Withdrawal failed');
  END IF;

  INSERT INTO public.governance_proposals (
    world_id, proposal_type, status, requested_by, payload
  ) VALUES (
    p_world_id,
    'treasury_withdrawal',
    'pending',
    v_user_id,
    jsonb_build_object(
      'amount', p_amount,
      'description', COALESCE(p_description, '')
    )
  )
  RETURNING id INTO v_proposal_id;

  INSERT INTO public.world_audit_log (world_id, actor_id, action, details)
  VALUES (
    p_world_id,
    v_user_id,
    'governance_treasury_proposed',
    jsonb_build_object(
      'proposal_id', v_proposal_id,
      'amount', p_amount,
      'description', COALESCE(p_description, ''),
      'status', 'pending'
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'executed', false,
    'proposal_id', v_proposal_id
  );
END;
$$;

-- ─── Proposal review: notify requester ───
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
  v_world_name TEXT;
  v_msg TEXT;
  v_type TEXT;
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

  SELECT name INTO v_world_name FROM public.worlds WHERE id = v_row.world_id;
  v_world_name := COALESCE(NULLIF(trim(v_world_name), ''), 'your world');

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

    v_type := 'governanceProposalRejected';
    v_msg := 'Council declined your ' ||
      replace(v_row.proposal_type, '_', ' ') || ' request in ' || v_world_name || '.';

    INSERT INTO public.notifications (
      id, recipient_id, type, message, world_id, actor_id, created_at
    )
    VALUES (
      gen_random_uuid()::text,
      v_row.requested_by,
      v_type,
      v_msg,
      v_row.world_id,
      v_user_id,
      extract(epoch from now())::bigint * 1000
    );

    RETURN jsonb_build_object('success', true, 'status', 'rejected');
  END IF;

  IF v_row.proposal_type = 'treasury_withdrawal' THEN
    v_amount := (v_row.payload->>'amount')::int;
    v_desc := COALESCE(v_row.payload->>'description', '');
    IF NOT public.withdraw_from_treasury(v_row.world_id, v_amount, v_desc) THEN
      RETURN jsonb_build_object('success', false, 'error', 'Treasury withdrawal failed');
    END IF;
    INSERT INTO public.world_audit_log (world_id, actor_id, action, details)
    VALUES (
      v_row.world_id,
      v_user_id,
      'governance_treasury_executed',
      jsonb_build_object(
        'proposal_id', p_proposal_id,
        'amount', v_amount,
        'description', v_desc,
        'status', 'executed'
      )
    );
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

  v_type := 'governanceProposalApproved';
  v_msg := 'Council approved your ' ||
    replace(v_row.proposal_type, '_', ' ') || ' request in ' || v_world_name || '.';

  INSERT INTO public.notifications (
    id, recipient_id, type, message, world_id, actor_id, created_at
  )
  VALUES (
    gen_random_uuid()::text,
    v_row.requested_by,
    v_type,
    v_msg,
    v_row.world_id,
    v_user_id,
    extract(epoch from now())::bigint * 1000
  );

  RETURN jsonb_build_object('success', true, 'status', 'executed');
END;
$$;
