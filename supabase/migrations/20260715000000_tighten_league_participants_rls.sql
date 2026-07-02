-- Tighten league_participants from "any authenticated user can manage any record"
-- to "anyone reads (leaderboard), user manages own records only".
-- Previously: FOR ALL TO authenticated USING (true) WITH CHECK (true)
-- (set in 20260520130000_security_corrective.sql)

DROP POLICY IF EXISTS league_participants_authenticated_manage ON public.league_participants;
DROP POLICY IF EXISTS league_participants_read ON public.league_participants;
DROP POLICY IF EXISTS league_participants_insert_own ON public.league_participants;
DROP POLICY IF EXISTS league_participants_update_own ON public.league_participants;
DROP POLICY IF EXISTS league_participants_delete_own ON public.league_participants;

CREATE POLICY league_participants_read ON public.league_participants
  FOR SELECT
  USING (true);

CREATE POLICY league_participants_insert_own ON public.league_participants
  FOR INSERT
  WITH CHECK (user_id = auth.uid()::text);

CREATE POLICY league_participants_update_own ON public.league_participants
  FOR UPDATE
  USING (user_id = auth.uid()::text);

CREATE POLICY league_participants_delete_own ON public.league_participants
  FOR DELETE
  USING (user_id = auth.uid()::text);
