-- Secure notification push fanout.
--
-- This migration keeps the database trigger reproducible without hardcoding any
-- webhook secret in SQL. Store the runtime secret in Supabase Vault as
-- `webhook_secret`; the Edge Function reads the same value from its
-- WEBHOOK_SECRET environment variable.

create extension if not exists pg_net with schema extensions;

create or replace function public.notify_push_on_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  webhook_url text := 'https://wjaphoaxalvgjnrwqjwe.supabase.co/functions/v1/send-push';
  webhook_secret text;
  request_headers jsonb;
begin
  if new.recipient_id is null then
    return new;
  end if;

  select decrypted_secret
    into webhook_secret
  from vault.decrypted_secrets
  where name = 'webhook_secret'
  limit 1;

  if webhook_secret is null or length(webhook_secret) = 0 then
    raise warning 'webhook_secret missing from Supabase Vault; skipping push notification fanout';
    return new;
  end if;

  request_headers := jsonb_build_object(
    'Authorization', 'Bearer ' || webhook_secret,
    'Content-Type', 'application/json'
  );

  perform net.http_post(
    url := webhook_url,
    headers := request_headers,
    body := jsonb_build_object(
      'record', row_to_json(new),
      'type', 'INSERT',
      'table', 'notifications',
      'schema', 'public'
    )
  );

  return new;
end;
$$;

drop trigger if exists on_notification_insert on public.notifications;
create trigger on_notification_insert
  after insert on public.notifications
  for each row
  execute function public.notify_push_on_insert();
