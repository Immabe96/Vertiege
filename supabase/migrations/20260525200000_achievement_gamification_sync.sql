-- G0: Server-authoritative achievement XP, in-app grants, reviewer notifications.

-- Remote may predate archived phase1 tier migrations; ensure gamification columns exist.
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS total_xp INT NOT NULL DEFAULT 0;
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS last_activity_at TIMESTAMPTZ;
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS prestige_level INT NOT NULL DEFAULT 0;
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS prestige_stars INT NOT NULL DEFAULT 0;
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS referral_xp_multiplier DECIMAL(3, 2) NOT NULL DEFAULT 1.0;
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS successful_referrals INT NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS public.achievement_definitions (
  id         TEXT PRIMARY KEY,
  xp_value   INT NOT NULL CHECK (xp_value >= 0),
  is_in_app  BOOLEAN NOT NULL DEFAULT false
);

ALTER TABLE public.achievement_definitions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS achievement_definitions_read ON public.achievement_definitions;
CREATE POLICY achievement_definitions_read ON public.achievement_definitions
  FOR SELECT TO authenticated
  USING (true);

ALTER TABLE public.user_achievements
  ADD COLUMN IF NOT EXISTS xp_applied_at TIMESTAMPTZ;

-- Seed catalog (mirrors lib/config/achievements.dart)
INSERT INTO public.achievement_definitions (id, xp_value, is_in_app) VALUES
  ('edu-hs', 50, false),
  ('edu-college', 200, false),
  ('edu-masters', 300, false),
  ('edu-phd', 500, false),
  ('edu-language', 100, false),
  ('edu-language2', 150, false),
  ('edu-cert', 100, false),
  ('car-first-job', 50, false),
  ('car-promotion', 150, false),
  ('car-switch', 100, false),
  ('car-business', 400, false),
  ('car-f500', 200, false),
  ('car-raise', 100, false),
  ('car-remote', 150, false),
  ('car-retire', 1000, false),
  ('rel-first-date', 30, false),
  ('rel-1year', 100, false),
  ('rel-5year', 300, false),
  ('rel-marriage', 500, false),
  ('rel-home', 400, false),
  ('rel-child', 800, false),
  ('rel-reconnect', 50, false),
  ('health-5k', 50, false),
  ('health-marathon', 300, false),
  ('health-weight', 150, false),
  ('health-gym', 200, false),
  ('health-swim', 80, false),
  ('health-tri', 400, false),
  ('health-quit', 250, false),
  ('health-meditate', 100, false),
  ('skill-code', 150, false),
  ('skill-instrument', 100, false),
  ('skill-cook', 50, false),
  ('skill-license', 80, false),
  ('skill-surf', 120, false),
  ('skill-speak', 100, false),
  ('skill-build', 200, false),
  ('trv-country', 100, false),
  ('trv-solo', 200, false),
  ('trv-abroad', 500, false),
  ('trv-7continents', 1000, false),
  ('trv-roadtrip', 200, false),
  ('trv-5star', 80, false),
  ('fin-save1k', 30, false),
  ('fin-invest', 100, false),
  ('fin-car', 200, false),
  ('fin-home', 1000, false),
  ('fin-emergency', 100, false),
  ('fin-debtfree', 500, false),
  ('com-volunteer', 100, false),
  ('com-blood', 75, false),
  ('com-mentor', 200, false),
  ('com-tree', 50, false),
  ('com-event', 300, false),
  ('fun-allnighter', 10, false),
  ('fun-reunion', 20, false),
  ('fun-pizza', 15, false),
  ('fun-lego', 50, false),
  ('fun-cat', 25, false),
  ('fun-hold', 20, false),
  ('fun-binge', 30, false),
  ('fun-edible', 20, false),
  ('fun-pet', 15, false),
  ('fun-ikea', 40, false),
  ('cre-book', 500, false),
  ('cre-art', 100, false),
  ('cre-song', 200, false),
  ('cre-yt', 150, false),
  ('cre-perform', 300, false),
  ('pioneer-poster', 10, true),
  ('voice-of-realm', 50, true),
  ('chronicler', 150, true),
  ('nexus-scribe', 300, true),
  ('explorer', 20, true),
  ('wayfarer', 60, true),
  ('realm-wanderer', 150, true),
  ('streak-3', 10, true),
  ('week-warrior', 50, true),
  ('streak-14', 100, true),
  ('month-master', 200, true),
  ('streak-60', 500, true),
  ('season-sage', 1000, true),
  ('streak-180', 2500, true),
  ('streak-365', 5000, true),
  ('prof-doctor', 200, false),
  ('prof-engineer', 200, false),
  ('prof-attorney', 200, false),
  ('prof-finance', 200, false),
  ('prof-artist', 200, false),
  ('prof-pilot', 200, false)
ON CONFLICT (id) DO UPDATE
  SET xp_value = EXCLUDED.xp_value,
      is_in_app = EXCLUDED.is_in_app;

CREATE OR REPLACE FUNCTION public.tier_level_from_xp(p_xp INT)
RETURNS INT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_xp >= 50000 THEN 5
    WHEN p_xp >= 10000 THEN 4
    WHEN p_xp >= 2000 THEN 3
    WHEN p_xp >= 500 THEN 2
    ELSE 1
  END;
$$;

CREATE OR REPLACE FUNCTION public._insert_achievement_notification(
  p_recipient_id TEXT,
  p_type TEXT,
  p_message TEXT
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  INSERT INTO public.notifications (
    id,
    recipient_id,
    type,
    message,
    read,
    created_at
  ) VALUES (
    gen_random_uuid()::text,
    p_recipient_id,
    p_type,
    left(trim(p_message), 500),
    false,
    now()
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.grant_verified_achievement(
  p_user_id TEXT,
  p_achievement_id TEXT,
  p_reviewer_notes TEXT DEFAULT NULL
) RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid TEXT;
  v_xp INT;
  v_in_app BOOLEAN;
  v_prev TEXT;
  v_xp_applied TIMESTAMPTZ;
  v_new_total INT;
BEGIN
  v_uid := auth.uid()::text;
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT xp_value, is_in_app INTO v_xp, v_in_app
  FROM public.achievement_definitions
  WHERE id = p_achievement_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Unknown achievement id';
  END IF;

  IF NOT (
    public.is_verifier()
    OR (v_uid = p_user_id AND v_in_app)
  ) THEN
    RAISE EXCEPTION 'Not allowed to grant this achievement';
  END IF;

  SELECT status, xp_applied_at
  INTO v_prev, v_xp_applied
  FROM public.user_achievements
  WHERE user_id = p_user_id AND achievement_id = p_achievement_id;

  INSERT INTO public.user_achievements (
    user_id,
    achievement_id,
    status,
    proof_uri,
    submitted_at,
    verified_at,
    ai_notes
  ) VALUES (
    p_user_id,
    p_achievement_id,
    'verified',
    'auto',
    now(),
    now(),
    NULLIF(trim(p_reviewer_notes), '')
  )
  ON CONFLICT (user_id, achievement_id) DO UPDATE SET
    status = 'verified',
    verified_at = COALESCE(public.user_achievements.verified_at, now()),
    ai_notes = COALESCE(
      NULLIF(trim(p_reviewer_notes), ''),
      public.user_achievements.ai_notes
    ),
    proof_uri = COALESCE(
      NULLIF(public.user_achievements.proof_uri, ''),
      EXCLUDED.proof_uri
    );

  IF v_xp_applied IS NULL THEN
    UPDATE public.profiles
    SET total_xp = total_xp + v_xp,
        tier = public.tier_level_from_xp(total_xp + v_xp),
        last_activity_at = now()
    WHERE id = p_user_id
    RETURNING total_xp INTO v_new_total;

    UPDATE public.user_achievements
    SET xp_applied_at = now()
    WHERE user_id = p_user_id AND achievement_id = p_achievement_id;
  ELSE
    SELECT total_xp INTO v_new_total FROM public.profiles WHERE id = p_user_id;
  END IF;

  IF public.is_verifier() THEN
    PERFORM public._insert_achievement_notification(
      p_user_id,
      'achievementApproved',
      COALESCE(
        NULLIF(trim(p_reviewer_notes), ''),
        'Your achievement was verified! You earned ' || v_xp || ' XP.'
      )
    );
  END IF;

  RETURN COALESCE(v_new_total, 0);
END;
$$;

CREATE OR REPLACE FUNCTION public.reject_achievement_submission(
  p_user_id TEXT,
  p_achievement_id TEXT,
  p_reviewer_notes TEXT DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid TEXT;
  v_xp INT;
BEGIN
  v_uid := auth.uid()::text;
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF NOT public.is_verifier() THEN
    RAISE EXCEPTION 'Verifier access required';
  END IF;

  SELECT xp_value INTO v_xp
  FROM public.achievement_definitions
  WHERE id = p_achievement_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Unknown achievement id';
  END IF;

  UPDATE public.user_achievements
  SET status = 'rejected',
      ai_notes = NULLIF(trim(p_reviewer_notes), '')
  WHERE user_id = p_user_id AND achievement_id = p_achievement_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No submission found for this achievement';
  END IF;

  PERFORM public._insert_achievement_notification(
    p_user_id,
    'achievementRejected',
    COALESCE(
      NULLIF(trim(p_reviewer_notes), ''),
      'Your achievement proof was not approved. You may submit again with clearer proof.'
    )
  );
END;
$$;

-- Backfill XP for rows verified before xp_applied_at existed.
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT ua.user_id, ua.achievement_id, d.xp_value
    FROM public.user_achievements ua
    JOIN public.achievement_definitions d ON d.id = ua.achievement_id
    WHERE ua.status = 'verified' AND ua.xp_applied_at IS NULL
  LOOP
    UPDATE public.profiles
    SET total_xp = total_xp + r.xp_value,
        tier = public.tier_level_from_xp(total_xp + r.xp_value),
        last_activity_at = now()
    WHERE id = r.user_id;

    UPDATE public.user_achievements
    SET xp_applied_at = now()
    WHERE user_id = r.user_id AND achievement_id = r.achievement_id;
  END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public._insert_achievement_notification(TEXT, TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.grant_verified_achievement(TEXT, TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.reject_achievement_submission(TEXT, TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.tier_level_from_xp(INT) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.tier_level_from_xp(INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.grant_verified_achievement(TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reject_achievement_submission(TEXT, TEXT, TEXT) TO authenticated;
