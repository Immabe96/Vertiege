-- Server-side vote for post-embedded polls (posts.poll JSON).
-- Clients must not rewrite tallies via posts.update.

CREATE OR REPLACE FUNCTION public.posts_guard_poll_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
  IF auth.role() = 'service_role' THEN
    RETURN NEW;
  END IF;
  IF TG_OP = 'UPDATE' AND NEW.poll IS DISTINCT FROM OLD.poll THEN
    IF current_setting('app.allow_poll_vote', true) = 'on' THEN
      RETURN NEW;
    END IF;
    NEW.poll := OLD.poll;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS posts_guard_poll_column ON public.posts;
CREATE TRIGGER posts_guard_poll_column
  BEFORE UPDATE ON public.posts
  FOR EACH ROW
  EXECUTE FUNCTION public.posts_guard_poll_column();

CREATE OR REPLACE FUNCTION public.vote_on_post_poll(
  p_post_id TEXT,
  p_option_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid TEXT := auth.uid()::text;
  v_poll JSONB;
  v_options JSONB;
  v_voters JSONB;
  v_opt JSONB;
  v_i INT;
  v_found BOOLEAN := false;
  v_new_options JSONB := '[]'::jsonb;
  v_vote_count INT;
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  IF p_post_id IS NULL OR length(trim(p_post_id)) = 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Post required');
  END IF;
  IF p_option_id IS NULL OR length(trim(p_option_id)) = 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Option required');
  END IF;

  PERFORM set_config('app.allow_poll_vote', 'on', true);

  SELECT poll INTO v_poll FROM public.posts WHERE id = p_post_id FOR UPDATE;
  IF v_poll IS NULL OR jsonb_typeof(v_poll) <> 'object' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Poll not found');
  END IF;

  v_options := COALESCE(v_poll->'options', '[]'::jsonb);
  v_voters := COALESCE(v_poll->'votedResidentIds', '[]'::jsonb);

  -- votedResidentIds is a JSON array of resident ids
  IF EXISTS (
    SELECT 1
    FROM jsonb_array_elements_text(v_voters) AS vid
    WHERE vid = v_uid
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Already voted', 'poll', v_poll);
  END IF;

  FOR v_i IN 0 .. GREATEST(jsonb_array_length(v_options) - 1, -1) LOOP
    v_opt := v_options->v_i;
    IF (v_opt->>'id') = p_option_id THEN
      v_found := true;
      v_vote_count := COALESCE((v_opt->>'voteCount')::int, 0) + 1;
      v_opt := jsonb_set(v_opt, '{voteCount}', to_jsonb(v_vote_count));
    END IF;
    v_new_options := v_new_options || jsonb_build_array(v_opt);
  END LOOP;

  IF NOT v_found THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid option');
  END IF;

  v_voters := v_voters || to_jsonb(v_uid);
  v_poll := jsonb_set(v_poll, '{options}', v_new_options);
  v_poll := jsonb_set(v_poll, '{votedResidentIds}', v_voters);

  UPDATE public.posts SET poll = v_poll WHERE id = p_post_id;

  RETURN jsonb_build_object('success', true, 'poll', v_poll);
END;
$$;

REVOKE ALL ON FUNCTION public.vote_on_post_poll(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.vote_on_post_poll(TEXT, TEXT) TO authenticated;
