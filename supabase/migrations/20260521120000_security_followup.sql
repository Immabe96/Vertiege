-- Baseline audit follow-up (2026-05-21)
-- Tighten debug_logs inserts, drop duplicate storage list policies,
-- revoke anon EXECUTE on mutating RPCs (keep RLS helper functions).

-- 1. debug_logs: tie inserts to authenticated user when resident_id is set
DROP POLICY IF EXISTS debug_logs_authenticated_insert ON public.debug_logs;
DROP POLICY IF EXISTS debug_logs_anyone_insert ON public.debug_logs;

CREATE POLICY debug_logs_authenticated_insert ON public.debug_logs
  FOR INSERT TO authenticated
  WITH CHECK (
    resident_id IS NULL
    OR resident_id = auth.uid()::text
  );

-- 2. Storage: remove duplicate broad SELECT policies (keep bucket-scoped reads)
DROP POLICY IF EXISTS avatars_read ON storage.objects;
DROP POLICY IF EXISTS post_media_read ON storage.objects;

-- 3. Revoke anon execute on mutating SECURITY DEFINER RPCs
REVOKE EXECUTE ON FUNCTION public.add_comment(text, text, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.add_league_xp(text, integer) FROM anon;
REVOKE EXECUTE ON FUNCTION public.add_post_comment_v2(text, text, text, text, text, text, integer) FROM anon;
REVOKE EXECUTE ON FUNCTION public.add_reaction(text, text, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.award_rep_milestone_xp(text, text, integer) FROM anon;
REVOKE EXECUTE ON FUNCTION public.create_listing(text, text, text, text, text, text, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.create_world_from_template(uuid, text, text, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.create_world_full(text, text, text, text, text, text, text, text[]) FROM anon;
REVOKE EXECUTE ON FUNCTION public.donate_to_treasury(text, integer, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.increment_comment_count(text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.increment_doc_views(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.increment_thread_count(text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.increment_world_members(text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.notify_push_on_insert() FROM anon;
REVOKE EXECUTE ON FUNCTION public.process_league_reset() FROM anon;
REVOKE EXECUTE ON FUNCTION public.record_analytics(text, date, text, integer) FROM anon;
REVOKE EXECUTE ON FUNCTION public.remove_reaction(text, text, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.toggle_post_reaction_v2(text, text, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.toggle_reaction(text, text, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.update_challenge_progress(uuid, integer) FROM anon;
REVOKE EXECUTE ON FUNCTION public.vote_on_poll(uuid, integer, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.withdraw_from_treasury(text, integer, text) FROM anon;

-- Re-grant authenticated on app-facing RPCs
GRANT EXECUTE ON FUNCTION public.create_world_full(text, text, text, text, text, text, text, text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.toggle_post_reaction_v2(text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.add_post_comment_v2(text, text, text, text, text, text, integer) TO authenticated;
