-- DM notification: persist chat_messages.id so notification taps can scroll to the message.
-- The FCM payload + Edge Function deliver message_id, and the app scrolls the chat list
-- to the target bubble after loadDmMessages completes.

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS message_id TEXT REFERENCES public.chat_messages(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_notifications_message_id
  ON public.notifications(message_id)
  WHERE message_id IS NOT NULL;

-- Re-define the DM trigger to populate message_id from NEW.id (the chat_messages row).
CREATE OR REPLACE FUNCTION public.notify_dm_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_recipient TEXT;
  v_preview TEXT;
  v_sender TEXT;
BEGIN
  SELECT rid INTO v_recipient
  FROM public.dm_rooms r
  CROSS JOIN LATERAL unnest(r.resident_ids) AS rid
  WHERE r.id = NEW.room_id
    AND rid <> NEW.sender_id
  LIMIT 1;

  IF v_recipient IS NULL OR v_recipient = '' THEN
    RETURN NEW;
  END IF;

  v_sender := COALESCE(NULLIF(trim(NEW.sender_name), ''), 'Someone');
  v_preview := COALESCE(NULLIF(trim(NEW.content), ''), 'Sent an image');
  IF length(v_preview) > 240 THEN
    v_preview := left(v_preview, 237) || '...';
  END IF;

  INSERT INTO public.notifications (
    id,
    recipient_id,
    type,
    message,
    room_id,
    message_id,
    read,
    created_at
  ) VALUES (
    'dm-' || NEW.id,
    v_recipient,
    'dmMessage',
    v_sender || ': ' || v_preview,
    NEW.room_id,
    NEW.id,
    false,
    COALESCE(NEW.created_at, now())
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS chat_messages_dm_notify ON public.chat_messages;
CREATE TRIGGER chat_messages_dm_notify
  AFTER INSERT ON public.chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_dm_message();

REVOKE ALL ON FUNCTION public.notify_dm_message() FROM PUBLIC;
