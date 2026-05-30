-- Waves 8–11: capability-enforced posts, commerce, governance proposals, challenge scope, profile display.

-- ─── Helpers ───
CREATE OR REPLACE FUNCTION public.world_member_standing_level(p_world_id TEXT)
RETURNS INT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT public.world_standing_level(
    (
      SELECT wm.rep
      FROM public.world_members wm
      WHERE wm.world_id = p_world_id
        AND wm.resident_id = auth.uid()::text
    )
  );
$$;

CREATE OR REPLACE FUNCTION public.can_post_announcement(p_world_id TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT public.is_council_or_above(p_world_id);
$$;

CREATE OR REPLACE FUNCTION public.can_create_world_poll(p_world_id TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT public.is_council_or_above(p_world_id)
    OR public.world_member_standing_level(p_world_id) >= 4;
$$;

GRANT EXECUTE ON FUNCTION public.world_member_standing_level(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_post_announcement(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_create_world_poll(TEXT) TO authenticated;

-- ─── Wave 8: create_post (server-enforced capabilities) ───
DROP FUNCTION IF EXISTS public.create_post(TEXT, TEXT, TEXT, JSONB, BOOLEAN, BOOLEAN, JSONB, JSONB, JSONB);

CREATE OR REPLACE FUNCTION public.create_post(
  p_world_id TEXT,
  p_content TEXT,
  p_image_url TEXT DEFAULT NULL,
  p_media JSONB DEFAULT '[]'::jsonb,
  p_is_announcement BOOLEAN DEFAULT false,
  p_is_decree BOOLEAN DEFAULT false,
  p_is_pinned BOOLEAN DEFAULT false,
  p_poll JSONB DEFAULT NULL,
  p_mentions JSONB DEFAULT '[]'::jsonb,
  p_hashtags JSONB DEFAULT '[]'::jsonb,
  p_scheduled_for TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id TEXT;
  v_post_id TEXT;
  v_profile RECORD;
  v_new_post RECORD;
BEGIN
  v_user_id := auth.uid()::text;
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  IF p_content IS NULL OR length(trim(p_content)) = 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Content required');
  END IF;

  IF NOT public.is_world_member(p_world_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not a member of this world');
  END IF;

  IF p_scheduled_for IS NOT NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Scheduled posts are not available yet');
  END IF;

  IF p_is_announcement AND NOT public.can_post_announcement(p_world_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Announcement requires council standing');
  END IF;

  IF p_is_decree AND NOT public.can_post_announcement(p_world_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Decree requires council standing');
  END IF;

  IF p_is_pinned AND NOT public.can_post_announcement(p_world_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Pinning requires council standing');
  END IF;

  IF p_poll IS NOT NULL AND p_poll <> 'null'::jsonb THEN
    RETURN jsonb_build_object('success', false, 'error', 'Polls must be created from the poll composer');
  END IF;

  SELECT name, avatar_url, tier INTO v_profile
  FROM public.profiles
  WHERE id = v_user_id;

  v_post_id := gen_random_uuid()::text;

  INSERT INTO public.posts (
    id, world_id, resident_id, resident_name, resident_avatar,
    author_id, author_name, author_avatar,
    content, image_url, media, tier_at_posting,
    is_announcement, is_decree, is_pinned, poll, mentions, hashtags,
    reactions, comments, comment_count, status
  ) VALUES (
    v_post_id, p_world_id, v_user_id, v_profile.name, v_profile.avatar_url,
    v_user_id, v_profile.name, v_profile.avatar_url,
    trim(p_content), p_image_url, COALESCE(p_media, '[]'::jsonb), COALESCE(v_profile.tier, 1),
    COALESCE(p_is_announcement, false), COALESCE(p_is_decree, false),
    COALESCE(p_is_pinned, false), p_poll, COALESCE(p_mentions, '[]'::jsonb),
    COALESCE(p_hashtags, '[]'::jsonb),
    '{}'::jsonb, '[]'::jsonb, 0, 'published'
  )
  RETURNING * INTO v_new_post;

  RETURN jsonb_build_object(
    'success', true,
    'post_id', v_post_id,
    'post', to_jsonb(v_new_post)
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

REVOKE ALL ON FUNCTION public.create_post(
  TEXT, TEXT, TEXT, JSONB, BOOLEAN, BOOLEAN, BOOLEAN, JSONB, JSONB, JSONB, TIMESTAMPTZ
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_post(
  TEXT, TEXT, TEXT, JSONB, BOOLEAN, BOOLEAN, BOOLEAN, JSONB, JSONB, JSONB, TIMESTAMPTZ
) TO authenticated;

-- ─── Wave 10: governance proposals ───
CREATE TABLE IF NOT EXISTS public.governance_proposals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  proposal_type TEXT NOT NULL CHECK (
    proposal_type IN ('treasury_withdrawal', 'job_publish', 'rank_change')
  ),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (
    status IN ('pending', 'approved', 'rejected', 'executed')
  ),
  requested_by TEXT NOT NULL REFERENCES public.profiles(id),
  reviewed_by TEXT REFERENCES public.profiles(id),
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  review_note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  reviewed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_governance_proposals_world_status
  ON public.governance_proposals (world_id, status, created_at DESC);

ALTER TABLE public.governance_proposals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS governance_proposals_read ON public.governance_proposals;
CREATE POLICY governance_proposals_read ON public.governance_proposals
  FOR SELECT USING (public.is_world_member(world_id));

DROP POLICY IF EXISTS governance_proposals_insert ON public.governance_proposals;
CREATE POLICY governance_proposals_insert ON public.governance_proposals
  FOR INSERT WITH CHECK (
    requested_by = auth.uid()::text
    AND public.is_world_member(world_id)
  );

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
      RETURN jsonb_build_object('success', true, 'executed', true);
    END IF;
    RETURN jsonb_build_object('success', false, 'error', 'Withdrawal failed');
  END IF;

  INSERT INTO public.governance_proposals (
    world_id, proposal_type, requested_by, payload
  ) VALUES (
    p_world_id,
    'treasury_withdrawal',
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
    'treasury_withdrawal_requested',
    jsonb_build_object('proposal_id', v_proposal_id, 'amount', p_amount)
  );

  RETURN jsonb_build_object(
    'success', true,
    'proposal_id', v_proposal_id,
    'status', 'pending'
  );
END;
$$;

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

CREATE OR REPLACE FUNCTION public.withdraw_from_treasury(
  p_world_id TEXT,
  p_amount INT,
  p_description TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_balance INT;
BEGIN
  IF auth.uid() IS NULL THEN RETURN FALSE; END IF;
  IF NOT public.is_council_or_above(p_world_id) THEN RETURN FALSE; END IF;
  IF p_amount IS NULL OR p_amount <= 0 THEN RETURN FALSE; END IF;

  SELECT balance INTO v_balance FROM public.world_treasury WHERE world_id = p_world_id;
  IF v_balance IS NULL OR v_balance < p_amount THEN RETURN FALSE; END IF;

  INSERT INTO public.treasury_transactions (world_id, user_id, transaction_type, amount, description)
  VALUES (p_world_id, auth.uid()::text, 'withdrawal', p_amount, COALESCE(p_description, ''));

  UPDATE public.world_treasury
  SET balance = balance - p_amount,
      total_spent = total_spent + p_amount
  WHERE world_id = p_world_id;

  RETURN TRUE;
END;
$$;

-- Veteran+ may create polls (council may still moderate via existing policies).
DROP POLICY IF EXISTS world_polls_insert ON public.world_polls;
CREATE POLICY world_polls_insert ON public.world_polls
  FOR INSERT WITH CHECK (
    created_by = auth.uid()::text
    AND public.can_create_world_poll(world_id)
  );

-- ─── Wave 9: subscription receipts + cosmetic grants ───
CREATE TABLE IF NOT EXISTS public.subscription_purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL,
  purchase_token TEXT NOT NULL,
  tier_granted TEXT NOT NULL,
  verified_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (purchase_token)
);

ALTER TABLE public.subscription_purchases ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS subscription_purchases_self ON public.subscription_purchases;
CREATE POLICY subscription_purchases_self ON public.subscription_purchases
  FOR SELECT USING (user_id = auth.uid()::text);

CREATE TABLE IF NOT EXISTS public.user_cosmetic_grants (
  user_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  cosmetic_id TEXT NOT NULL,
  source TEXT NOT NULL DEFAULT 'coins' CHECK (source IN ('coins', 'receipt', 'achievement')),
  granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, cosmetic_id)
);

ALTER TABLE public.user_cosmetic_grants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS user_cosmetic_grants_self ON public.user_cosmetic_grants;
CREATE POLICY user_cosmetic_grants_self ON public.user_cosmetic_grants
  FOR SELECT USING (user_id = auth.uid()::text);

CREATE OR REPLACE FUNCTION public.verify_subscription_purchase(
  p_product_id TEXT,
  p_purchase_token TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id TEXT;
  v_tier TEXT;
BEGIN
  v_user_id := auth.uid()::text;
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  IF p_purchase_token IS NULL OR length(trim(p_purchase_token)) < 8 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid purchase token');
  END IF;

  v_tier := CASE p_product_id
    WHEN 'subscription_patrician' THEN 'patrician'
    WHEN 'subscription_sovereign_elite' THEN 'sovereign_elite'
    ELSE NULL
  END;

  IF v_tier IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Unknown subscription product');
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.subscription_purchases
    WHERE purchase_token = p_purchase_token
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Purchase already redeemed');
  END IF;

  INSERT INTO public.subscription_purchases (user_id, product_id, purchase_token, tier_granted)
  VALUES (v_user_id, p_product_id, p_purchase_token, v_tier);

  UPDATE public.profiles
  SET subscription_tier = v_tier
  WHERE id = v_user_id;

  RETURN jsonb_build_object('success', true, 'tier', v_tier);
END;
$$;

CREATE OR REPLACE FUNCTION public.purchase_cosmetic_with_coins(
  p_cosmetic_id TEXT,
  p_coin_price INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id TEXT;
  v_balance INT;
  v_cosmetics JSONB;
BEGIN
  v_user_id := auth.uid()::text;
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  IF p_cosmetic_id IS NULL OR length(trim(p_cosmetic_id)) = 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid cosmetic');
  END IF;
  IF p_coin_price IS NULL OR p_coin_price <= 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid price');
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.user_cosmetic_grants
    WHERE user_id = v_user_id AND cosmetic_id = p_cosmetic_id
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Already owned');
  END IF;

  SELECT sovereign_coins, cosmetics INTO v_balance, v_cosmetics
  FROM public.profiles
  WHERE id = v_user_id
  FOR UPDATE;

  IF v_balance IS NULL OR v_balance < p_coin_price THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not enough sovereign coins');
  END IF;

  UPDATE public.profiles
  SET sovereign_coins = sovereign_coins - p_coin_price
  WHERE id = v_user_id;

  INSERT INTO public.user_cosmetic_grants (user_id, cosmetic_id, source)
  VALUES (v_user_id, p_cosmetic_id, 'coins');

  RETURN jsonb_build_object('success', true, 'cosmetic_id', p_cosmetic_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.equip_cosmetic(
  p_slot TEXT,
  p_cosmetic_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id TEXT;
  v_equipped JSONB;
BEGIN
  v_user_id := auth.uid()::text;
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  IF p_cosmetic_id IS NOT NULL AND length(trim(p_cosmetic_id)) > 0 THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.user_cosmetic_grants
      WHERE user_id = v_user_id AND cosmetic_id = p_cosmetic_id
    ) THEN
      RETURN jsonb_build_object('success', false, 'error', 'Cosmetic not owned');
    END IF;
  END IF;

  SELECT COALESCE(equipped_cosmetics, '{}'::jsonb) INTO v_equipped
  FROM public.profiles
  WHERE id = v_user_id
  FOR UPDATE;

  IF p_cosmetic_id IS NULL OR length(trim(p_cosmetic_id)) = 0 THEN
    v_equipped := v_equipped - p_slot;
  ELSE
    v_equipped := v_equipped || jsonb_build_object(p_slot, p_cosmetic_id);
  END IF;

  UPDATE public.profiles
  SET equipped_cosmetics = v_equipped
  WHERE id = v_user_id;

  RETURN jsonb_build_object('success', true, 'equipped', v_equipped);
END;
$$;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS display_title TEXT,
  ADD COLUMN IF NOT EXISTS equipped_cosmetics JSONB DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS leaderboard_opt_out BOOLEAN DEFAULT false;

-- ─── Wave 11: challenge scope + progress RPC ───
ALTER TABLE public.world_challenges
  ADD COLUMN IF NOT EXISTS scope TEXT NOT NULL DEFAULT 'world';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'world_challenges_scope_check'
  ) THEN
    ALTER TABLE public.world_challenges
      ADD CONSTRAINT world_challenges_scope_check
      CHECK (scope IN ('daily', 'world', 'season'));
  END IF;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE OR REPLACE FUNCTION public.update_challenge_progress(
  p_challenge_id UUID,
  p_contribution INT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_challenge RECORD;
  v_user_id TEXT;
BEGIN
  v_user_id := auth.uid()::text;
  IF v_user_id IS NULL THEN RETURN FALSE; END IF;
  IF p_contribution IS NULL OR p_contribution <= 0 THEN RETURN FALSE; END IF;

  SELECT * INTO v_challenge
  FROM public.world_challenges
  WHERE id = p_challenge_id AND is_active = TRUE;

  IF NOT FOUND THEN RETURN FALSE; END IF;
  IF NOT public.is_world_member(v_challenge.world_id) THEN RETURN FALSE; END IF;

  INSERT INTO public.challenge_progress (challenge_id, resident_id, contribution)
  VALUES (p_challenge_id, v_user_id, p_contribution)
  ON CONFLICT (challenge_id, resident_id)
  DO UPDATE SET contribution = challenge_progress.contribution + EXCLUDED.contribution;

  UPDATE public.world_challenges
  SET current_value = (
    SELECT COALESCE(SUM(contribution), 0)
    FROM public.challenge_progress
    WHERE challenge_id = p_challenge_id
  )
  WHERE id = p_challenge_id;

  RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.request_treasury_withdrawal(TEXT, INT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.review_governance_proposal(UUID, BOOLEAN, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.verify_subscription_purchase(TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.purchase_cosmetic_with_coins(TEXT, INT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.equip_cosmetic(TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_challenge_progress(UUID, INT) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.request_treasury_withdrawal(TEXT, INT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.review_governance_proposal(UUID, BOOLEAN, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.verify_subscription_purchase(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.purchase_cosmetic_with_coins(TEXT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.equip_cosmetic(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_challenge_progress(UUID, INT) TO authenticated;
