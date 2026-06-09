-- Wave S7: extend reports table to support chat message reports
-- Previously reports were post-only (post_id NOT NULL, world_id NOT NULL).
-- Now post_id is optional, message_id is added, and world_id is nullable
-- to support DM message reports.

ALTER TABLE public.reports
  ALTER COLUMN post_id DROP NOT NULL;

ALTER TABLE public.reports
  ALTER COLUMN world_id DROP NOT NULL;

ALTER TABLE public.reports
  ADD COLUMN IF NOT EXISTS message_id TEXT,
  ADD COLUMN IF NOT EXISTS channel_id TEXT;

-- Allow reports on messages even when no post is linked.
ALTER TABLE public.reports
  DROP CONSTRAINT IF EXISTS reports_post_id_fkey;

ALTER TABLE public.reports
  ADD CONSTRAINT reports_post_id_fkey
    FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE SET NULL;

-- A report must reference at least one target: post, message, or world.
ALTER TABLE public.reports
  ADD CONSTRAINT reports_target_check
    CHECK (post_id IS NOT NULL OR message_id IS NOT NULL OR world_id IS NOT NULL);

-- Index for verifier/admin review filtered by status.
CREATE INDEX IF NOT EXISTS idx_reports_status
  ON public.reports(status)
  WHERE status = 'pending';
