-- F31: server-side daily check-in (streak / shields / last_check_in).

CREATE OR REPLACE FUNCTION public.record_daily_check_in()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid TEXT;
  v_today TEXT;
  v_yesterday TEXT;
  v_day_before TEXT;
  v_last TEXT;
  v_streak INT;
  v_shields INT;
  v_new_streak INT;
  v_shield_used BOOLEAN := false;
  v_bonus INT;
BEGIN
  v_uid := auth.uid()::text;
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  v_today := to_char((now() AT TIME ZONE 'utc')::date, 'YYYY-MM-DD');
  v_yesterday := to_char(((now() AT TIME ZONE 'utc')::date - 1), 'YYYY-MM-DD');
  v_day_before := to_char(((now() AT TIME ZONE 'utc')::date - 2), 'YYYY-MM-DD');

  SELECT
    substring(COALESCE(last_check_in, '') from 1 for 10),
    COALESCE(streak_count, 0),
    COALESCE(streak_shields, 0)
  INTO v_last, v_streak, v_shields
  FROM public.profiles
  WHERE id = v_uid
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Profile not found';
  END IF;

  IF v_last = v_today THEN
    RETURN jsonb_build_object(
      'already_checked_in', true,
      'streak', v_streak,
      'bonus_xp', 0,
      'shield_used', false
    );
  END IF;

  IF v_last IS NULL OR v_last = '' THEN
    v_new_streak := 1;
  ELSIF v_last = v_yesterday THEN
    v_new_streak := v_streak + 1;
  ELSIF v_shields > 0 AND v_last = v_day_before THEN
    v_new_streak := v_streak + 1;
    v_shield_used := true;
    v_shields := v_shields - 1;
  ELSE
    v_new_streak := 1;
  END IF;

  v_bonus := CASE v_new_streak
    WHEN 3 THEN 10
    WHEN 7 THEN 50
    WHEN 14 THEN 100
    WHEN 30 THEN 200
    WHEN 60 THEN 500
    WHEN 90 THEN 1000
    WHEN 180 THEN 2500
    WHEN 365 THEN 5000
    ELSE 0
  END;

  UPDATE public.profiles
  SET
    last_check_in = v_today,
    streak_count = v_new_streak,
    streak_shields = v_shields
  WHERE id = v_uid;

  RETURN jsonb_build_object(
    'already_checked_in', false,
    'streak', v_new_streak,
    'bonus_xp', v_bonus,
    'shield_used', v_shield_used
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.record_daily_check_in() FROM anon;
REVOKE EXECUTE ON FUNCTION public.record_daily_check_in() FROM public;
GRANT EXECUTE ON FUNCTION public.record_daily_check_in() TO authenticated;
