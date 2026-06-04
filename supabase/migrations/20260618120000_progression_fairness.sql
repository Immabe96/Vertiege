-- Wave 18: cohort fairness, XP velocity logging, last_active, featured achievements, coin ledger.

-- ─── world_members activity ───
ALTER TABLE public.world_members
  ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMPTZ;

CREATE OR REPLACE FUNCTION public.touch_world_member_activity(p_world_id TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid TEXT;
BEGIN
  v_uid := auth.uid()::text;
  IF v_uid IS NULL OR p_world_id IS NULL THEN RETURN; END IF;
  UPDATE public.world_members
  SET last_active_at = now()
  WHERE world_id = p_world_id AND resident_id = v_uid;
END;
$$;

GRANT EXECUTE ON FUNCTION public.touch_world_member_activity(TEXT) TO authenticated;

-- ─── Featured achievements (max 3) on profile ───
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS featured_achievement_ids UUID[] NOT NULL DEFAULT '{}';

CREATE OR REPLACE FUNCTION public.set_featured_achievements(p_ids UUID[])
RETURNS UUID[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid TEXT;
  v_trimmed UUID[];
BEGIN
  v_uid := auth.uid()::text;
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  SELECT COALESCE(array_agg(x ORDER BY ord), '{}'::uuid[])
  INTO v_trimmed
  FROM (
    SELECT x, row_number() OVER () AS ord
    FROM unnest(COALESCE(p_ids, '{}'::uuid[])) AS x
    LIMIT 3
  ) s;

  UPDATE public.profiles
  SET featured_achievement_ids = v_trimmed
  WHERE id = v_uid;

  RETURN v_trimmed;
END;
$$;

GRANT EXECUTE ON FUNCTION public.set_featured_achievements(UUID[]) TO authenticated;

-- ─── XP velocity (log-only flag; soft daily cap 5000) ───
ALTER TABLE public.activity_xp_log
  ADD COLUMN IF NOT EXISTS velocity_flagged BOOLEAN NOT NULL DEFAULT false;

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
  v_awarded INT;
  v_daily INT;
  v_flagged BOOLEAN := false;
  v_daily_cap CONSTANT INT := 5000;
  v_flag_threshold CONSTANT INT := 4000;
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

  SELECT COALESCE(SUM(xp_awarded), 0)::int INTO v_daily
  FROM public.activity_xp_log
  WHERE user_id = p_user_id
    AND created_at > (now() - interval '24 hours');

  IF (v_daily + v_total_xp) > v_flag_threshold THEN
    v_flagged := true;
  END IF;

  v_awarded := v_total_xp;
  IF (v_daily + v_awarded) > v_daily_cap THEN
    v_awarded := GREATEST(0, v_daily_cap - v_daily);
    v_flagged := true;
  END IF;

  IF v_awarded <= 0 THEN
    INSERT INTO public.activity_xp_log (user_id, action_type, xp_awarded, multiplier, velocity_flagged)
    VALUES (p_user_id, p_action_type, 0, v_multiplier, true);
    RETURN 0;
  END IF;

  INSERT INTO public.activity_xp_log (user_id, action_type, xp_awarded, multiplier, velocity_flagged)
  VALUES (p_user_id, p_action_type, v_awarded, v_multiplier, v_flagged);

  UPDATE public.profiles
  SET total_xp = total_xp + v_awarded,
      tier = public.tier_level_from_xp(total_xp + v_awarded),
      last_activity_at = NOW()
  WHERE id = p_user_id;

  RETURN v_awarded;
END;
$$;

-- ─── Season cohort scores (materialized view) ───
CREATE TABLE IF NOT EXISTS public.season_cohort_weekly_archive (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  season_id TEXT NOT NULL,
  world_id TEXT NOT NULL,
  cohort_id UUID NOT NULL,
  member_count INT NOT NULL DEFAULT 0,
  avg_tier NUMERIC(6, 2),
  archived_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_season_cohort_weekly_archive_season
  ON public.season_cohort_weekly_archive (season_id, archived_at DESC);

ALTER TABLE public.season_cohort_members
  ADD COLUMN IF NOT EXISTS match_band TEXT;

DROP MATERIALIZED VIEW IF EXISTS public.season_cohort_scores;

CREATE MATERIALIZED VIEW public.season_cohort_scores AS
SELECT
  sc.id AS cohort_id,
  sc.season_id,
  sc.world_id,
  sc.display_name,
  count(scm.resident_id)::int AS member_count,
  COALESCE(avg(p.tier), 1)::numeric(6, 2) AS avg_tier,
  count(*) FILTER (WHERE p.last_activity_at > now() - interval '7 days')::int AS active_last_7d
FROM public.season_cohorts sc
LEFT JOIN public.season_cohort_members scm ON scm.cohort_id = sc.id
LEFT JOIN public.profiles p ON p.id = scm.resident_id
GROUP BY sc.id, sc.season_id, sc.world_id, sc.display_name;

CREATE UNIQUE INDEX IF NOT EXISTS idx_season_cohort_scores_cohort
  ON public.season_cohort_scores (cohort_id);

CREATE OR REPLACE FUNCTION public.refresh_season_cohort_scores()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW public.season_cohort_scores;
END;
$$;

REVOKE ALL ON FUNCTION public.refresh_season_cohort_scores() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.refresh_season_cohort_scores() TO authenticated;

CREATE OR REPLACE FUNCTION public.run_season_cohort_weekly_maintenance()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_archived INT := 0;
  r RECORD;
BEGIN
  FOR r IN
    SELECT
      sc.season_id,
      sc.world_id,
      sc.id AS cohort_id,
      count(scm.resident_id)::int AS member_count,
      COALESCE(avg(p.tier), 1)::numeric(6, 2) AS avg_tier
    FROM public.season_cohorts sc
    LEFT JOIN public.season_cohort_members scm ON scm.cohort_id = sc.id
    LEFT JOIN public.profiles p ON p.id = scm.resident_id
    JOIN public.global_seasons gs ON gs.id = sc.season_id AND gs.is_active = true
    GROUP BY sc.season_id, sc.world_id, sc.id
  LOOP
    INSERT INTO public.season_cohort_weekly_archive (
      season_id, world_id, cohort_id, member_count, avg_tier
    )
    VALUES (
      r.season_id, r.world_id, r.cohort_id, r.member_count, r.avg_tier
    );
    v_archived := v_archived + 1;
  END LOOP;

  PERFORM public.refresh_season_cohort_scores();
  RETURN v_archived;
END;
$$;

REVOKE ALL ON FUNCTION public.run_season_cohort_weekly_maintenance() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.run_season_cohort_weekly_maintenance() TO service_role;

-- Fair matchmaking band on cohort join
CREATE OR REPLACE FUNCTION public._season_match_band(p_tier INT, p_last_activity TIMESTAMPTZ)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_tier >= 5 THEN 'apex'
    WHEN p_tier >= 4 THEN 'veteran'
    WHEN p_tier >= 3 THEN 'established'
    WHEN COALESCE(p_last_activity, 'epoch'::timestamptz) > now() - interval '7 days' THEN 'active'
    ELSE 'rising'
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
  v_tier INT;
  v_last_activity TIMESTAMPTZ;
  v_band TEXT;
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

  SELECT tier, last_activity_at INTO v_tier, v_last_activity
  FROM public.profiles WHERE id = v_user_id;

  v_band := public._season_match_band(COALESCE(v_tier, 1), v_last_activity);

  INSERT INTO public.season_cohorts (season_id, world_id, display_name)
  VALUES (v_season_id, p_world_id, v_world_name || ' cohort')
  ON CONFLICT (season_id, world_id) DO UPDATE
  SET display_name = EXCLUDED.display_name
  RETURNING id INTO v_cohort_id;

  INSERT INTO public.season_cohort_members (cohort_id, resident_id, match_band)
  VALUES (v_cohort_id, v_user_id, v_band)
  ON CONFLICT (cohort_id, resident_id) DO UPDATE
  SET match_band = EXCLUDED.match_band;

  PERFORM public.seed_default_season_challenge(p_world_id);
  PERFORM public.touch_world_member_activity(p_world_id);

  SELECT count(*)::int INTO v_member_count
  FROM public.season_cohort_members
  WHERE cohort_id = v_cohort_id;

  RETURN jsonb_build_object(
    'success', true,
    'cohort_id', v_cohort_id,
    'season_id', v_season_id,
    'world_id', p_world_id,
    'display_name', v_world_name || ' cohort',
    'member_count', v_member_count,
    'match_band', v_band
  );
END;
$$;

-- ─── Coin ledger (append-only) ───
CREATE TABLE IF NOT EXISTS public.coin_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resident_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  amount INT NOT NULL,
  reason TEXT NOT NULL,
  balance_after INT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_coin_transactions_resident
  ON public.coin_transactions (resident_id, created_at DESC);

ALTER TABLE public.coin_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS coin_transactions_self_read ON public.coin_transactions;
CREATE POLICY coin_transactions_self_read ON public.coin_transactions
  FOR SELECT USING (resident_id = auth.uid()::text);

CREATE OR REPLACE FUNCTION public.grant_sovereign_coins(
  p_amount INT,
  p_reason TEXT DEFAULT 'grant'
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid TEXT;
  v_balance INT;
BEGIN
  v_uid := auth.uid()::text;
  IF v_uid IS NULL THEN RETURN 0; END IF;
  IF p_amount IS NULL OR p_amount = 0 THEN RETURN 0; END IF;

  UPDATE public.profiles
  SET sovereign_coins = GREATEST(0, sovereign_coins + p_amount)
  WHERE id = v_uid
  RETURNING sovereign_coins INTO v_balance;

  INSERT INTO public.coin_transactions (resident_id, amount, reason, balance_after)
  VALUES (v_uid, p_amount, left(COALESCE(p_reason, 'grant'), 120), v_balance);

  RETURN v_balance;
END;
$$;

GRANT EXECUTE ON FUNCTION public.grant_sovereign_coins(INT, TEXT) TO authenticated;

-- pg_cron (no-op if extension unavailable on project tier)
DO $cron$
BEGIN
  CREATE EXTENSION IF NOT EXISTS pg_cron;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'pg_cron not available: schedule run_season_cohort_weekly_maintenance manually on staging';
END;
$cron$;

DO $schedule$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.schedule(
      'vertiege-season-cohort-weekly',
      '0 6 * * 0',
      $$SELECT public.run_season_cohort_weekly_maintenance()$$
    );
    PERFORM cron.schedule(
      'vertiege-refresh-cohort-scores',
      '15 * * * *',
      $$SELECT public.refresh_season_cohort_scores()$$
    );
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'pg_cron schedule skipped (enable extension on staging): %', SQLERRM;
END;
$schedule$;

-- Include caller match band in cohort summary
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
  v_match_band TEXT;
  v_uid TEXT;
BEGIN
  v_uid := auth.uid()::text;

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

  IF v_uid IS NOT NULL THEN
    SELECT match_band INTO v_match_band
    FROM public.season_cohort_members
    WHERE cohort_id = v_row.id AND resident_id = v_uid;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'cohort', jsonb_build_object(
      'id', v_row.id,
      'season_id', v_row.season_id,
      'world_id', p_world_id,
      'display_name', v_row.display_name,
      'member_count', v_member_count,
      'match_band', v_match_band
    )
  );
END;
$$;
