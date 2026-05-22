-- PUBLIC grants imply anon can EXECUTE; revoke write RPCs from PUBLIC and anon.

DO $$
DECLARE
  fn RECORD;
BEGIN
  FOR fn IN
    SELECT
      n.nspname AS schema_name,
      p.proname AS func_name,
      pg_get_function_identity_arguments(p.oid) AS func_args
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prosecdef
      AND p.proname NOT IN (
        'handle_new_user',
        'notify_push_on_insert',
        'prevent_profile_escalation',
        'is_banned_from_world',
        'is_council_or_above',
        'is_dm_participant',
        'is_sovereign_or_council',
        'is_superuser',
        'is_verifier',
        'is_world_member',
        'is_world_sovereign',
        'process_league_reset'
      )
  LOOP
    EXECUTE format(
      'REVOKE EXECUTE ON FUNCTION %I.%I(%s) FROM PUBLIC, anon',
      fn.schema_name,
      fn.func_name,
      fn.func_args
    );
    EXECUTE format(
      'GRANT EXECUTE ON FUNCTION %I.%I(%s) TO authenticated',
      fn.schema_name,
      fn.func_name,
      fn.func_args
    );
  END LOOP;
END $$;

REVOKE EXECUTE ON FUNCTION public.process_league_reset() FROM PUBLIC, anon;
