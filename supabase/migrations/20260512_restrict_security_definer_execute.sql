-- Restrict direct RPC execution of SECURITY DEFINER functions that are only
-- needed by triggers/admin flows, plus anon access to the authenticated app RPC.

revoke execute on function public.handle_new_user() from anon, authenticated;
revoke execute on function public.prevent_profile_escalation() from anon, authenticated;
revoke execute on function public.rls_auto_enable() from anon, authenticated;

revoke execute on function public.increment_thread_count(msg_id uuid) from anon;
grant execute on function public.increment_thread_count(msg_id uuid) to authenticated;
