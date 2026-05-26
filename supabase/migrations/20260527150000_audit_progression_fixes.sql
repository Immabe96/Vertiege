-- Audit fixes: tier sync on activity XP, world activity persistence, ascension RPC.

-- ─── Activity XP updates tier (matches grant_verified_achievement) ───
CREATE OR REPLACE FUNCTION public.award_activity_xp(
  p_user_id TEXT,
  p_action_type TEXT,
  p_base_xp INT
) RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_referral_multiplier DECIMAL;
  v_tier_multiplier DECIMAL;
  v_multiplier DECIMAL;
  v_total_xp INT;
  v_new_total INT;
BEGIN
  IF p_user_id IS NULL OR length(trim(p_user_id)) = 0 THEN
    RETURN 0;
  END IF;
  IF p_base_xp IS NULL OR p_base_xp <= 0 THEN
    RETURN 0;
  END IF;

  SELECT COALESCE(referral_xp_multiplier, 1.0) INTO v_referral_multiplier
  FROM public.profiles WHERE id = p_user_id;

  SELECT COALESCE((perk_value->>'value')::DECIMAL, 1.0) INTO v_tier_multiplier
  FROM public.profiles p
  JOIN public.tier_perks tp ON tp.tier_level = p.tier
  WHERE p.id = p_user_id AND tp.perk_name = 'xp_multiplier';

  v_multiplier := v_referral_multiplier * v_tier_multiplier;
  v_total_xp := FLOOR(p_base_xp * v_multiplier);

  INSERT INTO public.activity_xp_log (user_id, action_type, xp_awarded, multiplier)
  VALUES (p_user_id, p_action_type, v_total_xp, v_multiplier);

  UPDATE public.profiles
  SET total_xp = total_xp + v_total_xp,
      tier = public.tier_level_from_xp(total_xp + v_total_xp),
      last_activity_at = NOW()
  WHERE id = p_user_id
  RETURNING total_xp INTO v_new_total;

  RETURN v_total_xp;
END;
$$;

UPDATE public.profiles
SET tier = public.tier_level_from_xp(COALESCE(total_xp, 0))
WHERE tier IS DISTINCT FROM public.tier_level_from_xp(COALESCE(total_xp, 0));

-- ─── Persist dominion world growth (activity_score) ───
CREATE OR REPLACE FUNCTION public.bump_world_activity_score(
  p_world_id TEXT,
  p_delta INT
) RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_new_score INT;
BEGIN
  IF p_world_id IS NULL OR length(trim(p_world_id)) = 0 THEN
    RETURN 0;
  END IF;
  IF p_delta IS NULL OR p_delta = 0 THEN
    SELECT activity_score INTO v_new_score FROM public.worlds WHERE id = p_world_id;
    RETURN COALESCE(v_new_score, 0);
  END IF;

  UPDATE public.worlds
  SET activity_score = GREATEST(0, COALESCE(activity_score, 0) + p_delta)
  WHERE id = p_world_id
    AND type = 'dominion'
  RETURNING activity_score INTO v_new_score;

  RETURN COALESCE(v_new_score, 0);
END;
$$;

REVOKE ALL ON FUNCTION public.bump_world_activity_score(TEXT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.bump_world_activity_score(TEXT, INT) TO authenticated;

-- ─── Server-authoritative Hall ascension ───
CREATE OR REPLACE FUNCTION public.ascend_prestige()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid TEXT := auth.uid()::text;
  v_stars INT;
  v_xp INT;
  v_tier INT;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT COALESCE(total_xp, 0), COALESCE(tier, 1), COALESCE(prestige_stars, 0)
  INTO v_xp, v_tier, v_stars
  FROM public.profiles
  WHERE id = v_uid;

  IF v_tier < 5 OR v_xp < 50000 THEN
    RAISE EXCEPTION 'Requires Apex tier and 50,000 XP';
  END IF;

  v_stars := v_stars + 1;

  UPDATE public.profiles
  SET prestige_stars = v_stars,
      prestige_level = v_stars,
      total_xp = 0,
      tier = 1,
      avatar_frame_id = 'prestige_' || v_stars::text
  WHERE id = v_uid;

  RETURN v_stars;
END;
$$;

REVOKE ALL ON FUNCTION public.ascend_prestige() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.ascend_prestige() TO authenticated;
