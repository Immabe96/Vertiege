-- Revoke anon EXECUTE on SECURITY DEFINER functions (mobile clients use authenticated JWT).
-- Keeps trigger/internal functions that must run as system roles.

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
      AND has_function_privilege('anon', p.oid, 'EXECUTE')
      AND p.proname NOT IN (
        'handle_new_user',
        'notify_push_on_insert',
        'prevent_profile_escalation'
      )
  LOOP
    EXECUTE format(
      'REVOKE EXECUTE ON FUNCTION %I.%I(%s) FROM anon',
      fn.schema_name,
      fn.func_name,
      fn.func_args
    );
  END LOOP;
END $$;
