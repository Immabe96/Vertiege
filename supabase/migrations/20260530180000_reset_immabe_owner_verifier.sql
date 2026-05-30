-- Reset Immabe account: remove superuser cheats; keep product owner + staff (verifier) access.
-- Target: ltyl.naughty@gmail.com (resident Immabe).
-- Sign out and sign in again after apply so JWT app_metadata refreshes.

WITH target_user AS (
  SELECT id::text AS id
  FROM auth.users
  WHERE lower(email) = lower('ltyl.naughty@gmail.com')
)
UPDATE auth.users u
SET raw_app_meta_data =
  (COALESCE(u.raw_app_meta_data, '{}'::jsonb) - 'is_superuser' - 'access_level')
  || jsonb_build_object(
    'role', 'verifier',
    'is_verifier', true,
    'is_superuser', false
  )
FROM target_user tu
WHERE u.id::text = tu.id;

WITH target_user AS (
  SELECT id::text AS id
  FROM auth.users
  WHERE lower(email) = lower('ltyl.naughty@gmail.com')
)
UPDATE public.profiles p
SET
  bio = COALESCE(NULLIF(p.bio, ''), 'Owner'),
  tier = 1,
  subscription_tier = 'free',
  prestige_level = 0,
  prestige_stars = 0,
  sovereign_coins = 0,
  verified_roles = ARRAY(
    SELECT DISTINCT role
    FROM unnest(
      ARRAY(
        SELECT r
        FROM unnest(COALESCE(p.verified_roles, ARRAY[]::text[])) AS r
        WHERE r NOT IN (
          'super_admin',
          'Aviation',
          'Medical',
          'Finance',
          'Legal',
          'Arts',
          'Technology',
          'Engineering'
        )
      ) || ARRAY['owner']::text[]
    ) AS role
    WHERE role IS NOT NULL AND role <> ''
    ORDER BY role
  ),
  wealth_worlds_unlocked = '{}',
  joined_world_ids = '{}',
  local_world_ids = '{}',
  world_standings = '{}'::jsonb,
  xp_multiplier = 1,
  daily_coin_bonus = 0,
  custom_reaction_slots = 0,
  post_pin_limit = 0,
  world_creation_limit = 1,
  onboarding_completed = true,
  gate_completed = true,
  updated_at = now()
FROM target_user tu
WHERE p.id = tu.id;

-- Remove auto-joined worlds / inflated rep from superuser grant.
WITH target_user AS (
  SELECT id::text AS id
  FROM auth.users
  WHERE lower(email) = lower('ltyl.naughty@gmail.com')
)
DELETE FROM public.world_members wm
USING target_user tu
WHERE wm.resident_id = tu.id;
