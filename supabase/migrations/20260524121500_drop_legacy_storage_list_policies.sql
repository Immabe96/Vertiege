-- Remove legacy broad SELECT policies superseded by path-scoped reads.

drop policy if exists "avatars public read" on storage.objects;
drop policy if exists "post-media public read" on storage.objects;
