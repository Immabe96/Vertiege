insert into public.world_members (world_id, resident_id, resident_name, rep, joined_at)
select distinct world_id, id, coalesce(nullif(name, ''), 'Member'), 0, now()
from public.profiles
cross join lateral unnest(joined_world_ids) as world_id
where joined_world_ids is not null
on conflict (world_id, resident_id) do nothing;

insert into public.world_members (world_id, resident_id, resident_name, rep, joined_at)
select distinct w.id, p.id, coalesce(nullif(p.name, ''), 'Member'), 0, now()
from public.profiles p
join public.worlds w on w.slug = any(p.local_world_ids)
where p.local_world_ids is not null
on conflict (world_id, resident_id) do nothing;
