-- ═══════════════════════════════════════════════════════════════
-- Vertiege — Supabase Storage Buckets & Policies
-- Run AFTER fresh_start.sql
-- ═══════════════════════════════════════════════════════════════

-- Create storage buckets (must be done via dashboard or API)
-- Dashboard: https://wjaphoaxalvgjnrwqjwe.supabase.co → Storage → New Bucket
--
-- Create these 3 buckets (all PUBLIC):
--   1. avatars          — file size limit: 5MB, allowed: jpg, png, webp, gif
--   2. post-media       — file size limit: 10MB, allowed: jpg, png, webp, gif
--   3. verification-proofs — file size limit: 10MB, allowed: jpg, png, pdf

-- After creating buckets via dashboard, run these SQL policies:

-- ── Avatars bucket policies ──────────────────────────────────
-- Public buckets serve known object URLs without a broad SELECT policy.
-- Do not add public read policies on storage.objects; they allow listing.

-- Allow authenticated users to upload their own avatar
CREATE POLICY avatars_auth_insert ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = 'avatars'
  );

-- Allow users to update/delete their own avatar
CREATE POLICY avatars_owner_update ON storage.objects
  FOR UPDATE
  USING (bucket_id = 'avatars' AND owner = auth.uid());

CREATE POLICY avatars_owner_delete ON storage.objects
  FOR DELETE
  USING (bucket_id = 'avatars' AND owner = auth.uid());

-- ── Post media bucket policies ───────────────────────────────
-- Public object URLs are enough for feed media display.

CREATE POLICY post_media_auth_insert ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'post-media'
    AND auth.role() = 'authenticated'
  );

CREATE POLICY post_media_owner_delete ON storage.objects
  FOR DELETE
  USING (bucket_id = 'post-media' AND owner = auth.uid());

-- ── Verification proofs bucket policies ──────────────────────
-- Verification proof URLs should be stored in app data, not discovered by
-- listing storage.objects.

CREATE POLICY proofs_auth_insert ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'verification-proofs'
    AND auth.role() = 'authenticated'
  );
