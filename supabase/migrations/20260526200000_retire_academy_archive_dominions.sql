-- Release 5: Retire academy and archive dominion types (data cleanup).
-- RPC validation for create_world_full is in 20260526210000.

DELETE FROM public.worlds
WHERE type = 'dominion'
  AND dominion_type IN ('academy', 'archive');

UPDATE public.profiles p
SET joined_world_ids = COALESCE(
  (
    SELECT array_agg(wid ORDER BY wid)
    FROM unnest(COALESCE(p.joined_world_ids, '{}')) AS wid
    WHERE EXISTS (SELECT 1 FROM public.worlds w WHERE w.id = wid)
  ),
  '{}'
)
WHERE joined_world_ids IS NOT NULL
  AND joined_world_ids <> '{}';
