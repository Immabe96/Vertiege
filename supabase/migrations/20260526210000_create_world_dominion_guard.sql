-- Guard create_world_full: only sanctuary + marketplace dominion types.

CREATE OR REPLACE FUNCTION public.create_world_full(
  p_name text,
  p_description text,
  p_sovereign_id text,
  p_sovereign_name text,
  p_icon text DEFAULT 'earth'::text,
  p_dominion_type text DEFAULT NULL::text,
  p_world_currency_name text DEFAULT NULL::text,
  p_tags text[] DEFAULT NULL::text[]
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_world_id TEXT;
  v_slug TEXT;
  v_channel_id TEXT;
  v_world JSONB;
  v_channels JSONB := '[]'::JSONB;
  v_channel_record RECORD;
BEGIN
  IF p_dominion_type IS NOT NULL
     AND p_dominion_type NOT IN ('sanctuary', 'marketplace') THEN
    RAISE EXCEPTION 'invalid dominion_type: only sanctuary and marketplace are supported'
      USING ERRCODE = 'check_violation';
  END IF;

  v_world_id := gen_random_uuid()::TEXT;
  v_slug := LOWER(REGEXP_REPLACE(TRIM(p_name), '[^a-z0-9]+', '-', 'gi'));
  v_slug := REGEXP_REPLACE(v_slug, '^-+|-+$', '', 'g');
  IF v_slug = '' THEN
    v_slug := 'world-' || SUBSTRING(v_world_id FROM 1 FOR 8);
  END IF;

  INSERT INTO public.worlds (
    id, slug, name, type, description, sovereign_id, sovereign_name,
    prestige, icon, is_default, sort_order, created_at,
    dominion_type, world_currency_name, tags
  ) VALUES (
    v_world_id, v_slug, p_name, 'dominion', p_description,
    p_sovereign_id, p_sovereign_name, 1, p_icon, false,
    (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT, NOW(),
    p_dominion_type, p_world_currency_name, p_tags
  );

  INSERT INTO public.world_members (
    world_id, resident_id, resident_name, rep, joined_at
  ) VALUES (
    v_world_id, p_sovereign_id, p_sovereign_name, 0, NOW()
  );

  UPDATE public.worlds SET member_count = 1 WHERE id = v_world_id;

  FOR v_channel_record IN
    SELECT * FROM (VALUES
      ('info', 'Start here for the world purpose, culture, and key links.', 'announcement', 0),
      ('rules', 'The standards, boundaries, and moderation expectations.', 'announcement', 1),
      ('roles', 'Rank, role, and permission guidance for residents.', 'announcement', 2),
      ('general', 'General discussion for all residents.', 'text', 3)
    ) AS ch(name, description, channel_type, position)
  LOOP
    v_channel_id := gen_random_uuid()::TEXT;
    INSERT INTO public.channels (
      id, world_id, name, description, channel_type, position,
      is_default, created_at
    ) VALUES (
      v_channel_id, v_world_id, v_channel_record.name,
      v_channel_record.description, v_channel_record.channel_type::public.channel_type,
      v_channel_record.position, true, NOW()
    );
    v_channels := v_channels || jsonb_build_object(
      'id', v_channel_id,
      'name', v_channel_record.name,
      'description', v_channel_record.description,
      'channel_type', v_channel_record.channel_type,
      'position', v_channel_record.position
    );
  END LOOP;

  v_world := jsonb_build_object(
    'id', v_world_id,
    'slug', v_slug,
    'name', p_name,
    'description', p_description,
    'sovereign_id', p_sovereign_id,
    'sovereign_name', p_sovereign_name,
    'icon', p_icon,
    'channels', v_channels
  );

  RETURN v_world;
END;
$function$;
