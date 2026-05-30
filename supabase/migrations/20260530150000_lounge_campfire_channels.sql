-- Wave 7: seed gated Lounge/Campfire channels for existing worlds.
-- UI and LiveKit token checks enforce prestige/standing access.

WITH channel_seed(name, description, channel_type, position) AS (
  VALUES
    (
      'lounge',
      'A high-standing resident lounge for trusted world conversation.',
      'text',
      4
    ),
    (
      'campfire',
      'Live voice for eligible lounge residents once audio rooms unlock.',
      'voice',
      5
    )
),
expanded AS (
  SELECT
    w.id AS world_id,
    cs.name,
    cs.description,
    cs.channel_type,
    cs.position
  FROM public.worlds w
  CROSS JOIN channel_seed cs
)
INSERT INTO public.channels (
  id,
  world_id,
  name,
  description,
  channel_type,
  position,
  is_default,
  created_at
)
SELECT
  world_id || '-' || name,
  world_id,
  name,
  description,
  channel_type,
  position,
  true,
  now()
FROM expanded
ON CONFLICT (id) DO UPDATE SET
  description = EXCLUDED.description,
  channel_type = EXCLUDED.channel_type,
  position = EXCLUDED.position,
  is_default = EXCLUDED.is_default;
