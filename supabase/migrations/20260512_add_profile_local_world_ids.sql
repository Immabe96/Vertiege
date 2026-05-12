-- Built-in catalog worlds use stable slug ids in the Flutter client, while
-- user-created Supabase worlds use UUIDs. Persist slug memberships separately
-- so onboarding/gate membership survives profile reloads.

alter table public.profiles
  add column if not exists local_world_ids text[] not null default '{}';
