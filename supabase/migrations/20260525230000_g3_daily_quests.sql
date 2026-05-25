-- G3: Server-backed daily quest progress + claim (award_activity_xp).

CREATE TABLE IF NOT EXISTS public.user_daily_quests (
  user_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  quest_date DATE NOT NULL DEFAULT (CURRENT_DATE AT TIME ZONE 'UTC'),
  quest_id TEXT NOT NULL,
  progress INT NOT NULL DEFAULT 0 CHECK (progress >= 0),
  target INT NOT NULL CHECK (target > 0),
  claimed BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, quest_date, quest_id)
);

CREATE INDEX IF NOT EXISTS idx_user_daily_quests_user_date
  ON public.user_daily_quests (user_id, quest_date);

ALTER TABLE public.user_daily_quests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS user_daily_quests_self ON public.user_daily_quests;
CREATE POLICY user_daily_quests_self ON public.user_daily_quests
  FOR ALL
  USING (user_id = auth.uid()::text)
  WITH CHECK (user_id = auth.uid()::text);

CREATE OR REPLACE FUNCTION public.upsert_daily_quest_progress(
  p_quest_id TEXT,
  p_progress INT,
  p_target INT DEFAULT 1
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid TEXT;
BEGIN
  v_uid := auth.uid()::text;
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF p_quest_id IS NULL OR length(trim(p_quest_id)) = 0 THEN
    RAISE EXCEPTION 'quest_id required';
  END IF;
  IF p_target IS NULL OR p_target <= 0 THEN
    RAISE EXCEPTION 'target must be positive';
  END IF;

  INSERT INTO public.user_daily_quests (
    user_id, quest_date, quest_id, progress, target, claimed, updated_at
  )
  VALUES (
    v_uid,
    (CURRENT_DATE AT TIME ZONE 'UTC')::date,
    p_quest_id,
    LEAST(GREATEST(p_progress, 0), p_target),
    p_target,
    false,
    now()
  )
  ON CONFLICT (user_id, quest_date, quest_id) DO UPDATE
  SET progress = LEAST(
        GREATEST(EXCLUDED.progress, user_daily_quests.progress),
        user_daily_quests.target
      ),
      target = EXCLUDED.target,
      updated_at = now();
END;
$$;

CREATE OR REPLACE FUNCTION public.claim_daily_quest(p_quest_id TEXT)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid TEXT;
  v_row public.user_daily_quests%ROWTYPE;
  v_xp INT;
BEGIN
  v_uid := auth.uid()::text;
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_row
  FROM public.user_daily_quests
  WHERE user_id = v_uid
    AND quest_date = (CURRENT_DATE AT TIME ZONE 'UTC')::date
    AND quest_id = p_quest_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Quest not started today';
  END IF;
  IF v_row.claimed THEN
    RETURN 0;
  END IF;
  IF v_row.progress < v_row.target THEN
    RAISE EXCEPTION 'Quest not complete';
  END IF;

  v_xp := v_row.target * 10;

  UPDATE public.user_daily_quests
  SET claimed = true, updated_at = now()
  WHERE user_id = v_uid
    AND quest_date = v_row.quest_date
    AND quest_id = p_quest_id;

  RETURN public.award_activity_xp(v_uid, 'daily_quest_' || p_quest_id, v_xp);
END;
$$;

REVOKE ALL ON FUNCTION public.upsert_daily_quest_progress(TEXT, INT, INT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.claim_daily_quest(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.upsert_daily_quest_progress(TEXT, INT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.claim_daily_quest(TEXT) TO authenticated;
