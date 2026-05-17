grant execute on function private.is_world_sovereign(uuid) to anon, authenticated;
grant execute on function private.is_dm_participant(uuid) to anon, authenticated;

drop policy if exists world_members_self_read on public.world_members;
create policy world_members_self_read
on public.world_members
for select
to authenticated
using (resident_id = (select auth.uid()));

drop policy if exists profiles_auth_insert on public.profiles;
create policy profiles_auth_insert
on public.profiles
for insert
to authenticated
with check (id = (select auth.uid()));

drop policy if exists profiles_auth_update on public.profiles;
create policy profiles_auth_update
on public.profiles
for update
to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));
