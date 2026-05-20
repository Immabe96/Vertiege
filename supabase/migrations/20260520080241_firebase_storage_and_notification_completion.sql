alter table public.device_tokens
  add column if not exists app_version text,
  add column if not exists build_number text,
  add column if not exists last_seen_at timestamptz not null default now();

create unique index if not exists device_tokens_token_key
  on public.device_tokens (token);

create index if not exists device_tokens_resident_id_idx
  on public.device_tokens (resident_id);

create index if not exists notifications_recipient_created_idx
  on public.notifications (recipient_id, created_at desc);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('post-media', 'post-media', true, 26214400, array['image/jpeg', 'image/png', 'image/webp', 'video/mp4']),
  ('world-banners', 'world-banners', true, 10485760, array['image/jpeg', 'image/png', 'image/webp']),
  ('world-icons', 'world-icons', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('marketplace-media', 'marketplace-media', true, 26214400, array['image/jpeg', 'image/png', 'image/webp', 'video/mp4']),
  ('chat-attachments', 'chat-attachments', true, 26214400, array['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'application/pdf']),
  ('verification-proofs', 'verification-proofs', false, 10485760, array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public can read app public media" on storage.objects;
drop policy if exists "Authenticated users can read verification proofs" on storage.objects;
drop policy if exists "Authenticated users can upload app media" on storage.objects;
drop policy if exists "Owners can update app media" on storage.objects;
drop policy if exists "Owners can delete app media" on storage.objects;
drop policy if exists "Superusers can manage app media" on storage.objects;

create policy "Public can read app public media"
  on storage.objects
  for select
  using (
    bucket_id in (
      'avatars',
      'post-media',
      'world-banners',
      'world-icons',
      'marketplace-media',
      'chat-attachments'
    )
  );

create policy "Authenticated users can read verification proofs"
  on storage.objects
  for select
  to authenticated
  using (bucket_id = 'verification-proofs');

create policy "Authenticated users can upload app media"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id in (
      'avatars',
      'post-media',
      'world-banners',
      'world-icons',
      'marketplace-media',
      'chat-attachments',
      'verification-proofs'
    )
  );

create policy "Owners can update app media"
  on storage.objects
  for update
  to authenticated
  using (
    owner = auth.uid()
    and bucket_id in (
      'avatars',
      'post-media',
      'world-banners',
      'world-icons',
      'marketplace-media',
      'chat-attachments',
      'verification-proofs'
    )
  )
  with check (
    owner = auth.uid()
    and bucket_id in (
      'avatars',
      'post-media',
      'world-banners',
      'world-icons',
      'marketplace-media',
      'chat-attachments',
      'verification-proofs'
    )
  );

create policy "Owners can delete app media"
  on storage.objects
  for delete
  to authenticated
  using (
    owner = auth.uid()
    and bucket_id in (
      'avatars',
      'post-media',
      'world-banners',
      'world-icons',
      'marketplace-media',
      'chat-attachments',
      'verification-proofs'
    )
  );

create policy "Superusers can manage app media"
  on storage.objects
  for all
  to authenticated
  using (public.is_superuser())
  with check (public.is_superuser());
