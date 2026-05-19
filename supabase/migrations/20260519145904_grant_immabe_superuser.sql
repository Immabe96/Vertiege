-- Grant Immabe app-level superuser access.
-- Uses auth app metadata plus public RLS helper/policies so access is durable.

CREATE OR REPLACE FUNCTION public.is_superuser()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
  SELECT COALESCE((auth.jwt() -> 'app_metadata' ->> 'is_superuser')::boolean, false)
    OR EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()::text
        AND 'super_admin' = ANY(COALESCE(p.verified_roles, ARRAY[]::text[]))
    );
$$;

WITH target_user AS (
  SELECT id::text AS id
  FROM auth.users
  WHERE lower(email) = lower('ltyl.naughty@gmail.com')
)
UPDATE auth.users u
SET raw_app_meta_data = COALESCE(u.raw_app_meta_data, '{}'::jsonb) ||
  jsonb_build_object(
    'role', 'super_admin',
    'is_superuser', true,
    'access_level', 'all'
  )
FROM target_user tu
WHERE u.id::text = tu.id;

WITH target_user AS (
  SELECT id::text AS id
  FROM auth.users
  WHERE lower(email) = lower('ltyl.naughty@gmail.com')
),
world_ids AS (
  SELECT COALESCE(array_agg(id ORDER BY sort_order, name), ARRAY[]::text[]) AS ids
  FROM public.worlds
),
standings AS (
  SELECT COALESCE(
    jsonb_object_agg(id, jsonb_build_object('rep', 100000)),
    '{}'::jsonb
  ) AS value
  FROM public.worlds
)
UPDATE public.profiles p
SET
  name = COALESCE(NULLIF(p.name, ''), 'Immabe'),
  bio = 'Dev/Owner',
  tier = 5,
  subscription_tier = 'sovereign_elite',
  prestige_level = GREATEST(COALESCE(p.prestige_level, 0), 99),
  prestige_stars = GREATEST(COALESCE(p.prestige_stars, 0), 99),
  sovereign_coins = GREATEST(COALESCE(p.sovereign_coins, 0), 1000000),
  verified_roles = (
    SELECT ARRAY(
      SELECT DISTINCT role
      FROM unnest(COALESCE(p.verified_roles, ARRAY[]::text[]) || ARRAY[
        'super_admin',
        'owner',
        'Aviation',
        'Medical',
        'Finance',
        'Legal',
        'Arts',
        'Technology',
        'Engineering'
      ]) AS role
      ORDER BY role
    )
  ),
  wealth_worlds_unlocked = world_ids.ids,
  joined_world_ids = world_ids.ids,
  world_standings = standings.value,
  xp_multiplier = GREATEST(COALESCE(p.xp_multiplier, 1), 9.99),
  daily_coin_bonus = GREATEST(COALESCE(p.daily_coin_bonus, 0), 1000),
  custom_reaction_slots = GREATEST(COALESCE(p.custom_reaction_slots, 0), 99),
  post_pin_limit = GREATEST(COALESCE(p.post_pin_limit, 0), 99),
  world_creation_limit = GREATEST(COALESCE(p.world_creation_limit, 0), 999),
  onboarding_completed = true,
  gate_completed = true,
  updated_at = now()
FROM target_user tu, world_ids, standings
WHERE p.id = tu.id;

WITH target_user AS (
  SELECT id::text AS id
  FROM auth.users
  WHERE lower(email) = lower('ltyl.naughty@gmail.com')
)
INSERT INTO public.world_members (world_id, resident_id, resident_name, rep)
SELECT w.id, tu.id, 'Immabe', 100000
FROM public.worlds w
CROSS JOIN target_user tu
ON CONFLICT (world_id, resident_id) DO UPDATE SET
  resident_name = EXCLUDED.resident_name,
  rep = GREATEST(public.world_members.rep, EXCLUDED.rep);

CREATE OR REPLACE FUNCTION public.is_world_member(check_world_id text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
BEGIN
  IF public.is_superuser() THEN
    RETURN true;
  END IF;

  RETURN EXISTS (
    SELECT 1
    FROM public.world_members
    WHERE world_id = check_world_id
      AND resident_id = auth.uid()::text
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.is_world_sovereign(check_world_id text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
BEGIN
  IF public.is_superuser() THEN
    RETURN true;
  END IF;

  RETURN EXISTS (
    SELECT 1
    FROM public.worlds
    WHERE id = check_world_id
      AND sovereign_id = auth.uid()::text
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.is_council_or_above(p_world_id text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
DECLARE
  v_user_id TEXT;
  v_rep INT;
BEGIN
  IF public.is_superuser() THEN
    RETURN true;
  END IF;

  v_user_id := auth.uid()::text;
  SELECT rep INTO v_rep
  FROM public.world_members
  WHERE world_id = p_world_id
    AND resident_id = v_user_id;

  RETURN COALESCE(v_rep, 0) >= 5000;
END;
$$;

DO $$
DECLARE
  table_record RECORD;
BEGIN
  FOR table_record IN
    SELECT c.relname AS table_name
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind = 'r'
      AND c.relrowsecurity
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON public.%I',
      'superuser_all_access',
      table_record.table_name
    );
    EXECUTE format(
      'CREATE POLICY %I ON public.%I FOR ALL TO authenticated USING (public.is_superuser()) WITH CHECK (public.is_superuser())',
      'superuser_all_access',
      table_record.table_name
    );
  END LOOP;
END $$;
