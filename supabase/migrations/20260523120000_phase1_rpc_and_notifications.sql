-- Phase 1: bind privileged RPCs to auth.uid(), lock league reset, server-side mention notifications.

-- ─── League XP: only the signed-in user may accrue weekly XP ───
CREATE OR REPLACE FUNCTION public.add_league_xp(
  p_user_id TEXT,
  p_amount INT
) RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_current_season UUID;
  v_new_xp INT;
  v_uid TEXT;
BEGIN
  v_uid := auth.uid()::text;
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF p_user_id IS DISTINCT FROM v_uid THEN
    RAISE EXCEPTION 'Cannot modify another user''s league XP';
  END IF;
  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION 'Invalid XP amount';
  END IF;

  SELECT id INTO v_current_season FROM public.league_seasons WHERE is_active = true LIMIT 1;

  IF v_current_season IS NULL THEN
    INSERT INTO public.league_seasons (start_date, end_date, is_active)
    VALUES (now(), now() + INTERVAL '7 days', true)
    RETURNING id INTO v_current_season;
  END IF;

  INSERT INTO public.league_participants (season_id, user_id, league_tier, weekly_xp)
  VALUES (v_current_season, p_user_id, 'bronze', p_amount)
  ON CONFLICT (season_id, user_id) DO UPDATE
  SET weekly_xp = league_participants.weekly_xp + p_amount,
      updated_at = now()
  RETURNING weekly_xp INTO v_new_xp;

  RETURN v_new_xp;
END;
$$;

-- ─── Profile XP: only the signed-in user ───
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
  v_multiplier DECIMAL(3,2) := 1.0;
  v_referral_multiplier DECIMAL(3,2) := 1.0;
  v_tier_multiplier DECIMAL(3,2) := 1.0;
  v_total_xp INT;
  v_uid TEXT;
BEGIN
  v_uid := auth.uid()::text;
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF p_user_id IS DISTINCT FROM v_uid THEN
    RAISE EXCEPTION 'Cannot award XP to another user';
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
      last_activity_at = NOW()
  WHERE id = p_user_id;

  RETURN v_total_xp;
END;
$$;

-- ─── @everyone mentions: server-side fan-out (bypasses self-only insert policy) ───
CREATE OR REPLACE FUNCTION public.broadcast_world_mention_notifications(
  p_world_id TEXT,
  p_sender_id TEXT,
  p_message TEXT
) RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid TEXT;
  v_count INT := 0;
  v_member RECORD;
BEGIN
  v_uid := auth.uid()::text;
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF p_sender_id IS DISTINCT FROM v_uid THEN
    RAISE EXCEPTION 'Sender must match authenticated user';
  END IF;
  IF p_world_id IS NULL OR length(trim(p_world_id)) = 0 THEN
    RETURN 0;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.world_members wm
    WHERE wm.world_id = p_world_id AND wm.resident_id = v_uid
  ) THEN
    RAISE EXCEPTION 'Not a member of this world';
  END IF;

  FOR v_member IN
    SELECT wm.resident_id
    FROM public.world_members wm
    WHERE wm.world_id = p_world_id
      AND wm.resident_id IS DISTINCT FROM p_sender_id
  LOOP
    INSERT INTO public.notifications (
      id,
      recipient_id,
      type,
      message,
      world_id,
      read,
      created_at
    ) VALUES (
      gen_random_uuid()::text,
      v_member.resident_id,
      'mention',
      coalesce(nullif(trim(p_message), ''), 'Someone mentioned everyone'),
      p_world_id,
      false,
      now()
    );
    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;

REVOKE ALL ON FUNCTION public.broadcast_world_mention_notifications(TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.broadcast_world_mention_notifications(TEXT, TEXT, TEXT) TO authenticated;

-- League reset is cron-only — not callable from the mobile client
REVOKE EXECUTE ON FUNCTION public.process_league_reset() FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.process_league_reset() FROM anon;

-- Ensure notifications insert policy matches production (self-only from client)
DROP POLICY IF EXISTS "notifications_insert" ON public.notifications;
CREATE POLICY "notifications_insert" ON public.notifications
  FOR INSERT TO authenticated
  WITH CHECK (recipient_id = auth.uid()::text);
