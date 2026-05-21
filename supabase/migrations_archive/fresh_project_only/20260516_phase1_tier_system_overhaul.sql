-- ═══════════════════════════════════════════════════════════════
-- 20260516_phase1_tier_system_overhaul.sql
-- Phase 1: Activity-Based XP, REP Bridge, Referral Multiplier
-- ═══════════════════════════════════════════════════════════════

-- ─── Activity XP Tracking ───
CREATE TABLE IF NOT EXISTS public.activity_xp_log (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  action_type   TEXT NOT NULL, -- 'post', 'comment', 'reaction', 'check_in', 'world_join', 'profession_verify'
  xp_awarded    INT NOT NULL,
  multiplier    DECIMAL(3,2) DEFAULT 1.0,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_activity_xp_user ON public.activity_xp_log(user_id, created_at DESC);

-- ─── Apex Prestige ───
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS prestige_level INT DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS prestige_stars INT DEFAULT 0;

-- ─── Referral Multiplier ───
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS referral_xp_multiplier DECIMAL(3,2) DEFAULT 1.0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS successful_referrals INT DEFAULT 0;

-- ─── Tier Perks ───
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS xp_multiplier DECIMAL(3,2) DEFAULT 1.0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS daily_coin_bonus INT DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS custom_reaction_slots INT DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS post_pin_limit INT DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS world_creation_limit INT DEFAULT 0;

-- ─── Tier Decay Tracking ───
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS last_activity_at TIMESTAMPTZ;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS tier_decay_warning_sent BOOLEAN DEFAULT FALSE;

-- ─── Tier Perks Configuration ───
CREATE TABLE IF NOT EXISTS public.tier_perks (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tier_level  INT NOT NULL,
  perk_name   TEXT NOT NULL,
  perk_type   TEXT NOT NULL,
  perk_value  JSONB NOT NULL,
  UNIQUE(tier_level, perk_name)
);

-- Seed tier perks
INSERT INTO public.tier_perks (tier_level, perk_name, perk_type, perk_value) VALUES
(1, 'base_xp_multiplier', 'xp_multiplier', '{"value": 1.0}'),
(1, 'base_coin_bonus', 'coin_bonus', '{"value": 0}'),
(1, 'base_reaction_slots', 'reaction_slots', '{"value": 0}'),
(1, 'base_pin_limit', 'pin_limit', '{"value": 0}'),
(1, 'base_world_limit', 'world_limit', '{"value": 1}'),
(2, 'xp_multiplier', 'xp_multiplier', '{"value": 1.1}'),
(2, 'coin_bonus', 'coin_bonus', '{"value": 5}'),
(2, 'reaction_slots', 'reaction_slots', '{"value": 3}'),
(2, 'pin_limit', 'pin_limit', '{"value": 1}'),
(2, 'world_limit', 'world_limit', '{"value": 2}'),
(3, 'xp_multiplier', 'xp_multiplier', '{"value": 1.25}'),
(3, 'coin_bonus', 'coin_bonus', '{"value": 15}'),
(3, 'reaction_slots', 'reaction_slots', '{"value": 5}'),
(3, 'pin_limit', 'pin_limit', '{"value": 3}'),
(3, 'world_limit', 'world_limit', '{"value": 1}'),
(3, 'lounge_access', 'lounge_access', '{"value": true}'),
(4, 'xp_multiplier', 'xp_multiplier', '{"value": 1.5}'),
(4, 'coin_bonus', 'coin_bonus', '{"value": 30}'),
(4, 'reaction_slots', 'reaction_slots', '{"value": 10}'),
(4, 'pin_limit', 'pin_limit', '{"value": 5}'),
(4, 'world_limit', 'world_limit', '{"value": 3}'),
(4, 'lounge_access', 'lounge_access', '{"value": true}'),
(4, 'governance_vote', 'governance_vote', '{"value": true}'),
(5, 'xp_multiplier', 'xp_multiplier', '{"value": 2.0}'),
(5, 'coin_bonus', 'coin_bonus', '{"value": 50}'),
(5, 'reaction_slots', 'reaction_slots', '{"value": 999}'),
(5, 'pin_limit', 'pin_limit', '{"value": 10}'),
(5, 'world_limit', 'world_limit', '{"value": 999}'),
(5, 'lounge_access', 'lounge_access', '{"value": true}'),
(5, 'governance_vote', 'governance_vote', '{"value": true}')
ON CONFLICT (tier_level, perk_name) DO NOTHING;

-- ─── RPC: Award Activity XP ───
CREATE OR REPLACE FUNCTION public.award_activity_xp(
  p_user_id TEXT,
  p_action_type TEXT,
  p_base_xp INT
) RETURNS INT AS $$
DECLARE
  v_multiplier DECIMAL(3,2) := 1.0;
  v_referral_multiplier DECIMAL(3,2) := 1.0;
  v_tier_multiplier DECIMAL(3,2) := 1.0;
  v_total_xp INT;
BEGIN
  -- Get referral multiplier
  SELECT COALESCE(referral_xp_multiplier, 1.0) INTO v_referral_multiplier
  FROM public.profiles WHERE id = p_user_id;

  -- Get tier multiplier from tier_perks
  SELECT COALESCE((perk_value->>'value')::DECIMAL, 1.0) INTO v_tier_multiplier
  FROM public.profiles p
  JOIN public.tier_perks tp ON tp.tier_level = p.tier
  WHERE p.id = p_user_id AND tp.perk_name = 'xp_multiplier';

  v_multiplier := v_referral_multiplier * v_tier_multiplier;
  v_total_xp := FLOOR(p_base_xp * v_multiplier);

  -- Log the XP award
  INSERT INTO public.activity_xp_log (user_id, action_type, xp_awarded, multiplier)
  VALUES (p_user_id, p_action_type, v_total_xp, v_multiplier);

  -- Update total XP
  UPDATE public.profiles
  SET total_xp = total_xp + v_total_xp,
      last_activity_at = NOW()
  WHERE id = p_user_id;

  RETURN v_total_xp;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- ─── RPC: REP to XP Bridge ───
CREATE OR REPLACE FUNCTION public.award_rep_milestone_xp(
  p_user_id TEXT,
  p_world_id TEXT,
  p_new_rep INT
) RETURNS INT AS $$
DECLARE
  v_xp_awarded INT := 0;
BEGIN
  -- Council standing (5000 REP) grants +500 XP
  IF p_new_rep >= 5000 THEN
    SELECT public.award_activity_xp(p_user_id, 'rep_council', 500) INTO v_xp_awarded;
  END IF;

  RETURN v_xp_awarded;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- ─── RPC: Update Tier Perks on Tier Change ───
CREATE OR REPLACE FUNCTION public.update_tier_perks()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.tier != OLD.tier THEN
    -- Update perks based on new tier
    NEW.xp_multiplier := COALESCE(
      (SELECT (perk_value->>'value')::DECIMAL FROM public.tier_perks WHERE tier_level = NEW.tier AND perk_name = 'xp_multiplier'),
      1.0
    );
    NEW.daily_coin_bonus := COALESCE(
      (SELECT (perk_value->>'value')::INT FROM public.tier_perks WHERE tier_level = NEW.tier AND perk_name = 'coin_bonus'),
      0
    );
    NEW.custom_reaction_slots := COALESCE(
      (SELECT (perk_value->>'value')::INT FROM public.tier_perks WHERE tier_level = NEW.tier AND perk_name = 'reaction_slots'),
      0
    );
    NEW.post_pin_limit := COALESCE(
      (SELECT (perk_value->>'value')::INT FROM public.tier_perks WHERE tier_level = NEW.tier AND perk_name = 'pin_limit'),
      0
    );
    NEW.world_creation_limit := COALESCE(
      (SELECT (perk_value->>'value')::INT FROM public.tier_perks WHERE tier_level = NEW.tier AND perk_name = 'world_limit'),
      0
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_tier_perks ON public.profiles;
CREATE TRIGGER trg_update_tier_perks
  BEFORE UPDATE OF tier ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_tier_perks();
