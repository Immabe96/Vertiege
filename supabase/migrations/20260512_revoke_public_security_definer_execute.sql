-- Revoke the default PUBLIC function grants so anon cannot reach these via RPC.
-- Re-grant only the app RPC that the Flutter client calls after sending a
-- thread reply.

revoke execute on function public.handle_new_user() from public;
revoke execute on function public.prevent_profile_escalation() from public;
revoke execute on function public.rls_auto_enable() from public;

revoke execute on function public.increment_thread_count(msg_id uuid) from public;
grant execute on function public.increment_thread_count(msg_id uuid) to authenticated;
