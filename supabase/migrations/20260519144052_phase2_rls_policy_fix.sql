-- Phase 2: RLS policy hardening for feed, channels, bookmarks, and related
-- app data. This migration is additive/idempotent and preserves the broader
-- public/member feed read behavior from earlier migrations.

-- Posts: add an explicit member-read policy without replacing the broader
-- posts_read policy that also allows public world posts.
DROP POLICY IF EXISTS "Members can read posts" ON public.posts;
CREATE POLICY "Members can read posts" ON public.posts
  FOR SELECT USING (
    deleted_at IS NULL
    AND EXISTS (
      SELECT 1
      FROM public.world_members wm
      WHERE wm.world_id = posts.world_id
        AND wm.resident_id = auth.uid()::text
    )
  );

-- Bookmarks: support both legacy user_id and resident_id actor columns.
DROP POLICY IF EXISTS "Users can read own bookmarks" ON public.bookmarks;
CREATE POLICY "Users can read own bookmarks" ON public.bookmarks
  FOR SELECT USING (COALESCE(user_id, resident_id) = auth.uid()::text);

-- Channels: allow members to read channels in worlds they joined.
DROP POLICY IF EXISTS "Members can read channels" ON public.channels;
CREATE POLICY "Members can read channels" ON public.channels
  FOR SELECT USING (
    EXISTS (
      SELECT 1
      FROM public.world_members wm
      WHERE wm.world_id = channels.world_id
        AND wm.resident_id = auth.uid()::text
    )
  );

-- Channel messages: allow members to read messages for joined-world channels.
DROP POLICY IF EXISTS "Members can read channel messages" ON public.channel_messages;
CREATE POLICY "Members can read channel messages" ON public.channel_messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1
      FROM public.channels ch
      JOIN public.world_members wm ON wm.world_id = ch.world_id
      WHERE ch.id = channel_messages.channel_id
        AND wm.resident_id = auth.uid()::text
    )
  );

-- Channel reads: users can read their own channel read markers.
DROP POLICY IF EXISTS "Users can read own channel reads" ON public.channel_reads;
CREATE POLICY "Users can read own channel reads" ON public.channel_reads
  FOR SELECT USING (resident_id = auth.uid()::text);

-- World memberships: members can see rosters for worlds they belong to.
DROP POLICY IF EXISTS "Members can read world members" ON public.world_members;
CREATE POLICY "Members can read world members" ON public.world_members
  FOR SELECT USING (
    world_id IN (
      SELECT wm.world_id
      FROM public.world_members wm
      WHERE wm.resident_id = auth.uid()::text
    )
  );

-- Notifications use recipient_id in the base schema, not resident_id.
DROP POLICY IF EXISTS "Users can read own notifications" ON public.notifications;
CREATE POLICY "Users can read own notifications" ON public.notifications
  FOR SELECT USING (recipient_id = auth.uid()::text);

-- Allies use receiver_id in the base schema, not recipient_id.
DROP POLICY IF EXISTS "Users can read own allies" ON public.allies;
CREATE POLICY "Users can read own allies" ON public.allies
  FOR SELECT USING (
    requester_id = auth.uid()::text OR receiver_id = auth.uid()::text
  );

-- Indexes for common query patterns.
CREATE INDEX IF NOT EXISTS idx_posts_world_created
  ON public.posts(world_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_world_author
  ON public.posts(world_id, author_id);
CREATE INDEX IF NOT EXISTS idx_bookmarks_actor_post
  ON public.bookmarks(COALESCE(user_id, resident_id), post_id);
CREATE INDEX IF NOT EXISTS idx_channels_world_default_name
  ON public.channels(world_id, is_default, name);
CREATE INDEX IF NOT EXISTS idx_channel_messages_channel_created
  ON public.channel_messages(channel_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_world_members_world_resident
  ON public.world_members(world_id, resident_id);
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_read
  ON public.notifications(recipient_id, read, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_allies_requester_receiver
  ON public.allies(requester_id, receiver_id);

-- Unique safeguards. world_members already has this in the base schema, but
-- the guarded block keeps existing projects consistent.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'uq_world_members_world_resident'
  ) THEN
    ALTER TABLE public.world_members
      ADD CONSTRAINT uq_world_members_world_resident
      UNIQUE (world_id, resident_id);
  END IF;
END $$;

-- Bookmarks have both user_id and resident_id across migrations; use an
-- expression index instead of a plain resident_id constraint.
CREATE UNIQUE INDEX IF NOT EXISTS uq_bookmarks_actor_post
  ON public.bookmarks(COALESCE(user_id, resident_id), post_id);
