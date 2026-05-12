-- Align DM chat messages with the app model so image messages and sender
-- display metadata survive a remote reload.
alter table public.chat_messages
  add column if not exists sender_name text,
  add column if not exists sender_avatar text,
  add column if not exists image_url text;
