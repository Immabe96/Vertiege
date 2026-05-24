-- F31: block client direct writes to XP and check-in fields.

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
    NEW.tier := OLD.tier;
    IF NEW.total_xp IS DISTINCT FROM OLD.total_xp THEN
      NEW.total_xp := OLD.total_xp;
    END IF;
    IF NEW.sovereign_coins > OLD.sovereign_coins THEN
      NEW.sovereign_coins := OLD.sovereign_coins;
    END IF;
    IF NEW.streak_count > OLD.streak_count + 1 THEN
      NEW.streak_count := OLD.streak_count;
    END IF;
    IF NEW.streak_shields > OLD.streak_shields + 1 THEN
      NEW.streak_shields := OLD.streak_shields;
    END IF;
    IF NEW.last_check_in IS DISTINCT FROM OLD.last_check_in
       AND NEW.last_check_in IS NOT NULL THEN
      NEW.last_check_in := OLD.last_check_in;
    END IF;
    IF OLD.gate_completed = true AND NEW.gate_completed = false THEN
      NEW.gate_completed := true;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;
