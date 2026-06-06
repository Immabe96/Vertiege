-- Realtime: push verified achievement updates to the resident's client
-- without waiting for the notifications insert round-trip.

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.user_achievements;
  END IF;
EXCEPTION
  WHEN duplicate_object THEN
    NULL;
END $$;

-- Ensure UPDATE payloads include status for postgres_changes filters.
ALTER TABLE public.user_achievements REPLICA IDENTITY FULL;

-- Realtime delivery requires SELECT RLS on subscribed rows.
DROP POLICY IF EXISTS achievements_self_read ON public.user_achievements;
CREATE POLICY achievements_self_read ON public.user_achievements
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid()::text);
