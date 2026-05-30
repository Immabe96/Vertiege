-- Run against production/staging after migrations (supabase db execute or SQL editor).
-- Expect zero rows for anon_definer_execute and maintenance_rpc_authenticated.

-- SECURITY DEFINER functions still executable by anon (should be empty).
SELECT
  p.proname,
  pg_get_function_identity_arguments(p.oid) AS args
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.prosecdef
  AND has_function_privilege('anon', p.oid, 'EXECUTE')
ORDER BY 1, 2;

-- Maintenance RPCs that must NOT be callable by authenticated app users.
SELECT
  p.proname,
  pg_get_function_identity_arguments(p.oid) AS args
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
    'process_league_reset',
    'handle_new_user',
    'notify_push_on_insert',
    'prevent_profile_escalation',
    'notify_dm_message',
    'rls_auto_enable',
    '_insert_achievement_notification'
  )
  AND has_function_privilege('authenticated', p.oid, 'EXECUTE')
ORDER BY 1, 2;
