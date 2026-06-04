-- Ensure award_activity_xp never writes NULL xp_awarded (fixes claim_daily_quest on stale DB).

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

  v_multiplier := COALESCE(v_referral_multiplier, 1.0) * COALESCE(v_tier_multiplier, 1.0);
  v_total_xp := GREATEST(1, FLOOR(p_base_xp * v_multiplier)::INT);

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
