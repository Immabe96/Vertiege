-- Vertiege — Phase 4: Weekly Ascension Leagues (20260516)
-- Duolingo-style weekly league system with promotion/demotion

-- ═══════════════════════════════════════════════════════════════
-- 1. League Seasons
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.league_seasons (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  start_date  TIMESTAMPTZ NOT NULL,
  end_date    TIMESTAMPTZ NOT NULL,
  is_active   BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.league_seasons ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "league_seasons_public_read" ON public.league_seasons;
CREATE POLICY "league_seasons_public_read" ON public.league_seasons FOR SELECT USING (true);

-- ═══════════════════════════════════════════════════════════════
-- 2. League Participants
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.league_participants (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  season_id   UUID NOT NULL REFERENCES public.league_seasons(id) ON DELETE CASCADE,
  user_id     TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  league_tier TEXT NOT NULL DEFAULT 'bronze' CHECK (league_tier IN ('bronze', 'silver', 'gold', 'platinum', 'diamond')),
  weekly_xp   INT NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now(),
  UNIQUE(season_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_league_participants_season_tier ON public.league_participants(season_id, league_tier);
CREATE INDEX IF NOT EXISTS idx_league_participants_tier_xp ON public.league_participants(league_tier, weekly_xp DESC);
CREATE INDEX IF NOT EXISTS idx_league_participants_user ON public.league_participants(user_id);

ALTER TABLE public.league_participants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "league_participants_read" ON public.league_participants;
DROP POLICY IF EXISTS "league_participants_self_update" ON public.league_participants;
DROP POLICY IF EXISTS "league_participants_service_manage" ON public.league_participants;
CREATE POLICY "league_participants_read" ON public.league_participants FOR SELECT USING (true);
CREATE POLICY "league_participants_self_update" ON public.league_participants FOR UPDATE USING (user_id = auth.uid()::text);
CREATE POLICY "league_participants_service_manage" ON public.league_participants FOR ALL USING (true);

-- ═══════════════════════════════════════════════════════════════
-- 3. RPC: Add League XP
-- ═══════════════════════════════════════════════════════════════

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
BEGIN
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

-- ═══════════════════════════════════════════════════════════════
-- 4. RPC: Process Weekly League Reset
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.process_league_reset()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_tier TEXT;
  v_tiers TEXT[] := ARRAY['bronze', 'silver', 'gold', 'platinum', 'diamond'];
  v_promote_count INT := 7;
  v_demote_count INT := 5;
  v_season_id UUID;
  v_new_season_id UUID;
  v_user RECORD;
  v_next_tier TEXT;
  v_prev_tier TEXT;
  v_tier_idx INT;
  v_rank INT;
  v_total INT;
BEGIN
  SELECT id INTO v_season_id FROM public.league_seasons WHERE is_active = true LIMIT 1;
  IF v_season_id IS NULL THEN RETURN; END IF;

  INSERT INTO public.league_seasons (start_date, end_date, is_active)
  VALUES (now(), now() + INTERVAL '7 days', true)
  RETURNING id INTO v_new_season_id;

  UPDATE public.league_seasons SET is_active = false WHERE id != v_new_season_id;

  FOR v_tier IN SELECT unnest(v_tiers) LOOP
    v_total := 0;
    FOR v_user IN
      SELECT user_id, league_tier
      FROM public.league_participants
      WHERE season_id = v_season_id AND league_tier = v_tier
      ORDER BY weekly_xp DESC, updated_at DESC
    LOOP
      v_total := v_total + 1;
      v_rank := v_total;

      IF v_rank <= v_promote_count THEN
        v_tier_idx := array_position(v_tiers, v_tier);
        IF v_tier_idx < array_length(v_tiers, 1) THEN
          v_next_tier := v_tiers[v_tier_idx + 1];
        ELSE
          v_next_tier := v_tier;
        END IF;
      ELSIF v_rank > (v_total - v_demote_count) AND v_total > v_demote_count THEN
        v_tier_idx := array_position(v_tiers, v_tier);
        IF v_tier_idx > 1 THEN
          v_prev_tier := v_tiers[v_tier_idx - 1];
        ELSE
          v_prev_tier := v_tier;
        END IF;
      ELSE
        v_next_tier := v_tier;
        v_prev_tier := v_tier;
      END IF;

      IF v_rank <= v_promote_count THEN
        INSERT INTO public.league_participants (season_id, user_id, league_tier, weekly_xp)
        VALUES (v_new_season_id, v_user.user_id, v_next_tier, 0);
      ELSIF v_rank > (v_total - v_demote_count) AND v_total > v_demote_count THEN
        INSERT INTO public.league_participants (season_id, user_id, league_tier, weekly_xp)
        VALUES (v_new_season_id, v_user.user_id, v_prev_tier, 0);
      ELSE
        INSERT INTO public.league_participants (season_id, user_id, league_tier, weekly_xp)
        VALUES (v_new_season_id, v_user.user_id, v_tier, 0);
      END IF;
    END LOOP;
  END LOOP;
END;
$$;
