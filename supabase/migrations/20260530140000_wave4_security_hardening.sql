-- Wave 4: Lock trigger/cron RPCs to service_role, harden award_rep_milestone_xp,
-- restore intentional RLS read policies for reference/audit tables.

-- ─── Maintenance / trigger-only RPCs (not callable from mobile JWT) ───
REVOKE EXECUTE ON FUNCTION public.process_league_reset() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.process_league_reset() TO service_role;

REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO service_role;

REVOKE EXECUTE ON FUNCTION public.notify_push_on_insert() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.notify_push_on_insert() TO service_role;

REVOKE EXECUTE ON FUNCTION public.prevent_profile_escalation() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.prevent_profile_escalation() TO service_role;

REVOKE EXECUTE ON FUNCTION public.notify_dm_message() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.notify_dm_message() TO service_role;

REVOKE EXECUTE ON FUNCTION public.rls_auto_enable() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.rls_auto_enable() TO service_role;

REVOKE EXECUTE ON FUNCTION public._insert_achievement_notification(
  TEXT, TEXT, TEXT
) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public._insert_achievement_notification(
  TEXT, TEXT, TEXT
) TO service_role;

-- ─── Rep milestone XP: must target the signed-in user only ───
CREATE OR REPLACE FUNCTION public.award_rep_milestone_xp(
  p_user_id TEXT,
  p_world_id TEXT,
  p_new_rep INT
) RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_xp_awarded INT := 0;
  v_uid TEXT;
BEGIN
  v_uid := auth.uid()::text;
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF p_user_id IS DISTINCT FROM v_uid THEN
    RAISE EXCEPTION 'Cannot award rep milestone XP for another user';
  END IF;

  IF p_new_rep >= 5000 THEN
    SELECT public.award_activity_xp(p_user_id, 'rep_council', 500)
    INTO v_xp_awarded;
  END IF;

  RETURN v_xp_awarded;
END;
$$;

REVOKE ALL ON FUNCTION public.award_rep_milestone_xp(TEXT, TEXT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.award_rep_milestone_xp(TEXT, TEXT, INT) TO authenticated;

-- ─── RLS: explicit read policies (tables had RLS on but zero policies) ───
DROP POLICY IF EXISTS "activity_xp_self_read" ON public.activity_xp_log;
CREATE POLICY "activity_xp_self_read"
  ON public.activity_xp_log
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid()::text);

DROP POLICY IF EXISTS "tier_perks_public_read" ON public.tier_perks;
CREATE POLICY "tier_perks_public_read"
  ON public.tier_perks
  FOR SELECT
  TO authenticated, anon
  USING (true);
