grant usage on schema private to anon, authenticated;

grant execute on function private.is_world_member(uuid) to anon, authenticated;
grant execute on function private.is_banned_from_world(uuid) to anon, authenticated;
grant execute on function private.is_council_or_above(uuid) to anon, authenticated;
