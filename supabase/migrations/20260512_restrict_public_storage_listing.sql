-- Public buckets can still serve objects by public URL without broad SELECT
-- policies on storage.objects. Dropping these prevents bucket enumeration.

drop policy if exists avatars_public_read on storage.objects;
drop policy if exists post_media_public_read on storage.objects;
drop policy if exists proofs_public_read on storage.objects;
