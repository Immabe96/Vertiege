-- Keep world channel messages aligned with the in-app message model.
alter table public.channel_messages
  add column if not exists sender_avatar text,
  add column if not exists image_url text;
