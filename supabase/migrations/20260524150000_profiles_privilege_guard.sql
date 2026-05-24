-- Prevent authenticated users from escalating privileged profile columns via direct UPDATE.
-- Client writes should use safe fields only; this trigger is defense in depth (F02).

CREATE OR REPLACE FUNCTION public.profiles_guard_privileged_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
  IF auth.role() = 'service_role' THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' AND auth.uid() IS NOT NULL AND auth.uid()::text = OLD.id::text THEN
    -- Tier and economy fields are server/RPC managed.
    NEW.tier := OLD.tier;
    IF NEW.sovereign_coins > OLD.sovereign_coins THEN
      NEW.sovereign_coins := OLD.sovereign_coins;
    END IF;
    -- Streak cannot jump more than one day per client write.
    IF NEW.streak_count > OLD.streak_count + 1 THEN
      NEW.streak_count := OLD.streak_count;
    END IF;
    IF NEW.streak_shields > OLD.streak_shields + 1 THEN
      NEW.streak_shields := OLD.streak_shields;
    END IF;
    -- Gate cannot be un-completed from the client.
    IF OLD.gate_completed = true AND NEW.gate_completed = false THEN
      NEW.gate_completed := true;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_guard_privileged_columns ON public.profiles;
CREATE TRIGGER profiles_guard_privileged_columns
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.profiles_guard_privileged_columns();
