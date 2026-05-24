-- Tighten public bucket SELECT policies to block directory listing while
-- keeping read access for known object paths (avatars, post-media).

drop policy if exists "Public can read app public media" on storage.objects;
drop policy if exists "Read avatars by resident path" on storage.objects;
drop policy if exists "Read post media by uploader path" on storage.objects;
drop policy if exists "Read other public app media by bucket" on storage.objects;

create policy "Read avatars by resident path"
  on storage.objects
  for select
  using (
    bucket_id = 'avatars'
    and (
      name ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.[a-z0-9]+$'
      or name ~ '^avatars/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.[a-z0-9]+$'
    )
  );

create policy "Read post media by uploader path"
  on storage.objects
  for select
  using (
    bucket_id = 'post-media'
    and name ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}_[0-9]+\.[a-z0-9]+$'
  );

create policy "Read other public app media by bucket"
  on storage.objects
  for select
  using (
    bucket_id in (
      'world-banners',
      'world-icons',
      'marketplace-media',
      'chat-attachments'
    )
    and name !~ '^$'
    and name !~ '/$'
  );
