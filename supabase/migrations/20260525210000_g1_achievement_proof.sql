-- G1: Multi-image proof storage + life achievement catalog entries.

ALTER TABLE public.user_achievements
  ADD COLUMN IF NOT EXISTS proof_uris JSONB NOT NULL DEFAULT '[]'::jsonb;

-- Backfill single proof_uri into array where missing.
UPDATE public.user_achievements
SET proof_uris = jsonb_build_array(proof_uri)
WHERE proof_uri IS NOT NULL
  AND proof_uri <> ''
  AND proof_uri <> 'manual'
  AND proof_uri LIKE 'http%'
  AND (proof_uris IS NULL OR proof_uris = '[]'::jsonb);

INSERT INTO public.achievement_definitions (id, xp_value, is_in_app) VALUES
  ('life-midnight-snack', 15, false),
  ('life-plant-parent', 40, false),
  ('life-roadtrip', 120, false),
  ('life-confession', 80, false),
  ('life-chaos-king', 25, false),
  ('life-secret-talent', 100, false),
  ('life-survived-monday', 10, false),
  ('life-found-love', 200, false),
  ('life-dark-humor', 30, false),
  ('life-main-character', 50, false)
ON CONFLICT (id) DO UPDATE
  SET xp_value = EXCLUDED.xp_value,
      is_in_app = EXCLUDED.is_in_app;
