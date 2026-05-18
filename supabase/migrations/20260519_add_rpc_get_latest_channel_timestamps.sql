-- ─── RPC: Get Latest Channel Message Timestamps ───
-- Purpose: Optimized query to solve N+1 problem fetching latest messages
CREATE OR REPLACE FUNCTION public.get_latest_channel_message_timestamps(
  p_channel_ids TEXT[]
) RETURNS TABLE (
  channel_id TEXT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT cm.channel_id, MAX(cm.created_at) AS created_at
  FROM public.channel_messages cm
  WHERE cm.channel_id = ANY(p_channel_ids)
  GROUP BY cm.channel_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;
