-- Audit lockdown: economy RPCs, profile privilege columns, storage, member counts.
-- Addresses Vertiege in-depth audit P0/P1 Supabase findings (Jul 2026).

-- ─── S01: award_activity_xp must bind to caller ───
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
  v_caller TEXT := auth.uid()::text;
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
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  -- Callers may only award XP to themselves. Peer awards must use server triggers.
  IF p_user_id IS DISTINCT FROM v_caller THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;
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
  v_awarded := GREATEST(1, (p_base_xp * v_multiplier)::INT);

  SELECT COALESCE(SUM(xp_awarded), 0) INTO v_daily
  FROM public.activity_xp_log
  WHERE user_id = p_user_id
    AND created_at >= date_trunc('day', NOW() AT TIME ZONE 'UTC');

  IF v_daily >= v_daily_cap THEN
    INSERT INTO public.activity_xp_log (user_id, action_type, xp_awarded, multiplier, velocity_flagged)
    VALUES (p_user_id, p_action_type, 0, v_multiplier, true);
    RETURN 0;
  END IF;

  IF v_daily + v_awarded > v_daily_cap THEN
    v_awarded := GREATEST(0, v_daily_cap - v_daily);
  END IF;
  IF v_daily + v_awarded >= v_flag_threshold THEN
    v_flagged := true;
  END IF;

  INSERT INTO public.activity_xp_log (user_id, action_type, xp_awarded, multiplier, velocity_flagged)
  VALUES (p_user_id, p_action_type, v_awarded, v_multiplier, v_flagged);

  UPDATE public.profiles
  SET total_xp = total_xp + v_awarded,
      last_activity_at = NOW()
  WHERE id = p_user_id
  RETURNING total_xp INTO v_total_xp;

  -- Soft tier sync from XP thresholds (existing behavior may vary; keep XP write only if column exists path)
  PERFORM public.sync_tier_from_xp(p_user_id);

  RETURN v_awarded;
EXCEPTION
  WHEN undefined_function THEN
    RETURN v_awarded;
END;
$$;

REVOKE ALL ON FUNCTION public.award_activity_xp(TEXT, TEXT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.award_activity_xp(TEXT, TEXT, INT) TO authenticated;

-- ─── S02: revoke client coin mint ───
REVOKE ALL ON FUNCTION public.grant_sovereign_coins(INT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.grant_sovereign_coins(INT, TEXT) FROM authenticated;
REVOKE ALL ON FUNCTION public.grant_sovereign_coins(INT, TEXT) FROM anon;
GRANT EXECUTE ON FUNCTION public.grant_sovereign_coins(INT, TEXT) TO service_role;

-- ─── S04: bump_world_member_rep internal only ───
REVOKE ALL ON FUNCTION public.bump_world_member_rep(TEXT, TEXT, INT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.bump_world_member_rep(TEXT, TEXT, INT) FROM authenticated;
REVOKE ALL ON FUNCTION public.bump_world_member_rep(TEXT, TEXT, INT) FROM anon;
GRANT EXECUTE ON FUNCTION public.bump_world_member_rep(TEXT, TEXT, INT) TO service_role;
-- SECURITY DEFINER sibling functions (purchase_listing, create_listing) still call it as owner.

-- ─── S03: revoke direct IAP stub RPC from clients (edge/service_role only) ───
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'verify_subscription_purchase'
  ) THEN
    EXECUTE 'REVOKE ALL ON FUNCTION public.verify_subscription_purchase FROM PUBLIC';
    EXECUTE 'REVOKE ALL ON FUNCTION public.verify_subscription_purchase FROM authenticated';
    EXECUTE 'REVOKE ALL ON FUNCTION public.verify_subscription_purchase FROM anon';
    EXECUTE 'GRANT EXECUTE ON FUNCTION public.verify_subscription_purchase TO service_role';
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'verify_subscription_purchase revoke skipped: %', SQLERRM;
END $$;

-- ─── S05: freeze privilege profile columns ───
CREATE OR REPLACE FUNCTION public.profiles_guard_privileged_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
  IF auth.role() = 'service_role' THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' AND auth.uid() IS NOT NULL AND auth.uid()::text = OLD.id::text THEN
    NEW.tier := OLD.tier;
    IF NEW.total_xp IS DISTINCT FROM OLD.total_xp THEN
      NEW.total_xp := OLD.total_xp;
    END IF;
    IF NEW.sovereign_coins > OLD.sovereign_coins THEN
      NEW.sovereign_coins := OLD.sovereign_coins;
    END IF;
    IF NEW.streak_count > OLD.streak_count + 1 THEN
      NEW.streak_count := OLD.streak_count;
    END IF;
    IF NEW.streak_shields > OLD.streak_shields + 1 THEN
      NEW.streak_shields := OLD.streak_shields;
    END IF;
    IF NEW.last_check_in IS DISTINCT FROM OLD.last_check_in
       AND NEW.last_check_in IS NOT NULL THEN
      NEW.last_check_in := OLD.last_check_in;
    END IF;
    IF OLD.gate_completed = true AND NEW.gate_completed = false THEN
      NEW.gate_completed := true;
    END IF;
    -- Privilege / economy columns: never client-writable
    IF NEW.subscription_tier IS DISTINCT FROM OLD.subscription_tier THEN
      NEW.subscription_tier := OLD.subscription_tier;
    END IF;
    IF NEW.verified_roles IS DISTINCT FROM OLD.verified_roles THEN
      NEW.verified_roles := OLD.verified_roles;
    END IF;
    IF NEW.world_standings IS DISTINCT FROM OLD.world_standings THEN
      NEW.world_standings := OLD.world_standings;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- ─── S07: create_listing membership + auth ───
CREATE OR REPLACE FUNCTION public.create_listing(
  p_world_id TEXT,
  p_title TEXT,
  p_description TEXT,
  p_price INT,
  p_category TEXT DEFAULT 'general',
  p_image_url TEXT DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid TEXT := auth.uid()::text;
  v_id UUID;
  v_seller_id TEXT;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF p_world_id IS NULL OR length(trim(p_world_id)) = 0 THEN
    RAISE EXCEPTION 'World required';
  END IF;
  IF NOT public.is_world_member(p_world_id) THEN
    RAISE EXCEPTION 'Not a member of this world';
  END IF;
  IF p_price IS NULL OR p_price < 0 THEN
    RAISE EXCEPTION 'Invalid price';
  END IF;

  v_seller_id := v_uid;
  INSERT INTO public.marketplace_listings (
    world_id, seller_id, title, description, price, category, image_url, status
  ) VALUES (
    p_world_id, v_seller_id,
    left(COALESCE(p_title, 'Listing'), 120),
    left(COALESCE(p_description, ''), 2000),
    p_price,
    left(COALESCE(p_category, 'general'), 40),
    p_image_url,
    'active'
  )
  RETURNING id INTO v_id;

  PERFORM public.bump_world_member_rep(p_world_id, v_seller_id, 2);
  RETURN v_id;
EXCEPTION
  WHEN undefined_table THEN
    RAISE;
  WHEN undefined_column THEN
    -- Older schema variants
    INSERT INTO public.listings (
      world_id, seller_id, title, description, price, image_url, status
    ) VALUES (
      p_world_id, v_seller_id,
      left(COALESCE(p_title, 'Listing'), 120),
      left(COALESCE(p_description, ''), 2000),
      p_price, p_image_url, 'active'
    )
    RETURNING id INTO v_id;
    PERFORM public.bump_world_member_rep(p_world_id, v_seller_id, 2);
    RETURN v_id;
END;
$$;

-- ─── S11: member_count via trigger; revoke client RPCs ───
CREATE OR REPLACE FUNCTION public.trg_sync_world_member_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.worlds
    SET member_count = COALESCE(member_count, 0) + 1
    WHERE id = NEW.world_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.worlds
    SET member_count = GREATEST(0, COALESCE(member_count, 0) - 1)
    WHERE id = OLD.world_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS world_members_sync_count ON public.world_members;
CREATE TRIGGER world_members_sync_count
  AFTER INSERT OR DELETE ON public.world_members
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_sync_world_member_count();

REVOKE ALL ON FUNCTION public.increment_world_members(TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.increment_world_members(TEXT) FROM authenticated;
REVOKE ALL ON FUNCTION public.increment_world_members(TEXT) FROM anon;
REVOKE ALL ON FUNCTION public.decrement_world_members(TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.decrement_world_members(TEXT) FROM authenticated;
REVOKE ALL ON FUNCTION public.decrement_world_members(TEXT) FROM anon;

-- ─── S12: cohort refresh cron/service only ───
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'refresh_season_cohort_scores'
  ) THEN
    EXECUTE 'REVOKE ALL ON FUNCTION public.refresh_season_cohort_scores() FROM PUBLIC';
    EXECUTE 'REVOKE ALL ON FUNCTION public.refresh_season_cohort_scores() FROM authenticated';
    EXECUTE 'REVOKE ALL ON FUNCTION public.refresh_season_cohort_scores() FROM anon';
    EXECUTE 'GRANT EXECUTE ON FUNCTION public.refresh_season_cohort_scores() TO service_role';
  END IF;
END $$;

-- ─── increment_thread_count: revoke client ───
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'increment_thread_count'
  ) THEN
    EXECUTE 'REVOKE ALL ON FUNCTION public.increment_thread_count FROM PUBLIC';
    EXECUTE 'REVOKE ALL ON FUNCTION public.increment_thread_count FROM authenticated';
    EXECUTE 'REVOKE ALL ON FUNCTION public.increment_thread_count FROM anon';
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'increment_thread_count revoke skipped: %', SQLERRM;
END $$;

-- ─── S09/S10: storage — verification proofs owner-only read; path-scoped inserts ───
DROP POLICY IF EXISTS "Authenticated can read verification proofs" ON storage.objects;
DROP POLICY IF EXISTS verification_proofs_select ON storage.objects;
CREATE POLICY verification_proofs_owner_select ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'verification-proofs'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Verifiers may read proofs (role claim on JWT or profiles.verified_roles)
DROP POLICY IF EXISTS verification_proofs_verifier_select ON storage.objects;
CREATE POLICY verification_proofs_verifier_select ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'verification-proofs'
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()::text
        AND (
          p.verified_roles @> ARRAY['verifier']::text[]
          OR p.verified_roles @> ARRAY['super_admin']::text[]
        )
    )
  );

DROP POLICY IF EXISTS "Authenticated can upload to app buckets" ON storage.objects;
DROP POLICY IF EXISTS storage_authenticated_insert ON storage.objects;

-- Path-scoped inserts for sensitive / user media buckets
DROP POLICY IF EXISTS storage_owner_insert_verification ON storage.objects;
CREATE POLICY storage_owner_insert_verification ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'verification-proofs'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS storage_owner_insert_post_media ON storage.objects;
CREATE POLICY storage_owner_insert_post_media ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'post-media'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS storage_owner_insert_chat ON storage.objects;
CREATE POLICY storage_owner_insert_chat ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'chat-attachments'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS storage_owner_insert_avatars ON storage.objects;
CREATE POLICY storage_owner_insert_avatars ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
