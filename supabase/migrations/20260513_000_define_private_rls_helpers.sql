create schema if not exists private;

create or replace function private.is_world_member(check_world_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.world_members
    where world_id = check_world_id
      and resident_id = (select auth.uid())
  );
$$;

create or replace function private.is_world_sovereign(check_world_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.worlds
    where id = check_world_id
      and sovereign_id = (select auth.uid())
  );
$$;

create or replace function private.is_council_or_above(check_world_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.world_members
    where world_id = check_world_id
      and resident_id = (select auth.uid())
      and rep >= 5000
  ) or private.is_world_sovereign(check_world_id);
$$;

create or replace function private.is_banned_from_world(check_world_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.moderation_logs
    where world_id = check_world_id
      and target_user_id = (select auth.uid())
      and action = 'ban'
  );
$$;

create or replace function private.is_dm_participant(check_room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.dm_rooms
    where id = check_room_id
      and resident_ids @> array[(select auth.uid())]::uuid[]
  );
$$;

grant usage on schema private to anon, authenticated;
grant execute on function private.is_world_member(uuid) to anon, authenticated;
grant execute on function private.is_world_sovereign(uuid) to anon, authenticated;
grant execute on function private.is_council_or_above(uuid) to anon, authenticated;
grant execute on function private.is_banned_from_world(uuid) to anon, authenticated;
grant execute on function private.is_dm_participant(uuid) to anon, authenticated;
