-- Correct recursive world_members RLS introduced by phase2_rls_policy_fix.
-- Final state: membership checks use a SECURITY DEFINER helper that bypasses
-- world_members RLS instead of querying world_members from its own policy.

CREATE SCHEMA IF NOT EXISTS private;

CREATE OR REPLACE FUNCTION private.has_world_membership(
  p_world_id text,
  p_resident_id text DEFAULT auth.uid()::text
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $$
  SELECT
    COALESCE(public.is_superuser(), false)
    OR EXISTS (
      SELECT 1
      FROM public.world_members wm
      WHERE wm.world_id = p_world_id
        AND wm.resident_id = p_resident_id
    );
$$;

REVOKE ALL ON FUNCTION private.has_world_membership(text, text) FROM PUBLIC;
GRANT USAGE ON SCHEMA private TO authenticated;
GRANT EXECUTE ON FUNCTION private.has_world_membership(text, text) TO authenticated;

DROP POLICY IF EXISTS "Members can read world members" ON public.world_members;
DROP POLICY IF EXISTS "world_members_read" ON public.world_members;
CREATE POLICY "world_members_read" ON public.world_members
  FOR SELECT
  TO authenticated
  USING (
    resident_id = auth.uid()::text
    OR private.has_world_membership(world_id, auth.uid()::text)
  );

DROP POLICY IF EXISTS "Members can read posts" ON public.posts;
DROP POLICY IF EXISTS "posts_read" ON public.posts;
CREATE POLICY "posts_read" ON public.posts
  FOR SELECT
  TO authenticated
  USING (
    deleted_at IS NULL
    AND private.has_world_membership(world_id, auth.uid()::text)
  );

DROP POLICY IF EXISTS "Members can read channels" ON public.channels;
DROP POLICY IF EXISTS "channels_read" ON public.channels;
CREATE POLICY "channels_read" ON public.channels
  FOR SELECT
  TO authenticated
  USING (private.has_world_membership(world_id, auth.uid()::text));

DROP POLICY IF EXISTS "Members can read channel messages" ON public.channel_messages;
DROP POLICY IF EXISTS "channel_messages_read" ON public.channel_messages;
CREATE POLICY "channel_messages_read" ON public.channel_messages
  FOR SELECT
  TO authenticated
  USING (private.has_world_membership(world_id, auth.uid()::text));

DROP POLICY IF EXISTS "channel_messages_insert" ON public.channel_messages;
CREATE POLICY "channel_messages_insert" ON public.channel_messages
  FOR INSERT
  TO authenticated
  WITH CHECK (
    sender_id = auth.uid()::text
    AND private.has_world_membership(world_id, auth.uid()::text)
    AND NOT public.is_banned_from_world(world_id)
  );
