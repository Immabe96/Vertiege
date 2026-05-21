-- ═══════════════════════════════════════════════════════════════
-- 20260516_security_and_integrity_fixes.sql
-- Fixes for audit findings: RLS policies, FK constraints, data integrity
-- ═══════════════════════════════════════════════════════════════

-- ─── C1: Restrict notification INSERT to self-only ───
-- Table: notifications (recipient_id TEXT, type TEXT, message TEXT, world_id TEXT, post_id TEXT, read BOOLEAN)
DROP POLICY IF EXISTS "notifications_insert" ON public.notifications;
CREATE POLICY "notifications_insert" ON public.notifications
  FOR INSERT WITH CHECK (recipient_id = auth.uid()::text);

-- ─── C2: Restrict verification council update to council members ───
-- Table: verification_submissions (resident_id, resident_name, profession, proof_url, status, reviewer_notes, reviewed_by)
-- No world_id column — check council/sovereign status across ALL worlds
DROP POLICY IF EXISTS "verification_council_update" ON public.verification_submissions;
CREATE POLICY "verification_council_update" ON public.verification_submissions
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.world_members wm
      WHERE wm.resident_id = auth.uid()::text
        AND wm.rep >= 5000
    )
    OR EXISTS (
      SELECT 1 FROM public.worlds w
      WHERE w.sovereign_id = auth.uid()::text
    )
  );

-- ─── C7: Add FK to reports.reporter_id ───
-- Table: reports (id, world_id, post_id, reporter_id, reason, details, status)
-- reporter_id is TEXT NOT NULL, no existing FK
ALTER TABLE public.reports
  DROP CONSTRAINT IF EXISTS reports_reporter_id_fkey,
  ADD CONSTRAINT reports_reporter_id_fkey
    FOREIGN KEY (reporter_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- ─── C8: Add FK to districts.world_id ───
-- Table: districts (id, world_id TEXT NOT NULL, name, position)
-- world_id has no FK
ALTER TABLE public.districts
  DROP CONSTRAINT IF EXISTS districts_world_id_fkey,
  ADD CONSTRAINT districts_world_id_fkey
    FOREIGN KEY (world_id) REFERENCES public.worlds(id) ON DELETE CASCADE;

-- ─── C9: Add FK to world_audit_log.world_id ───
-- Table: world_audit_log (id, world_id TEXT NOT NULL, actor_id, target_id, action, details, created_at)
-- world_id has no FK
ALTER TABLE public.world_audit_log
  DROP CONSTRAINT IF EXISTS world_audit_log_world_id_fkey,
  ADD CONSTRAINT world_audit_log_world_id_fkey
    FOREIGN KEY (world_id) REFERENCES public.worlds(id) ON DELETE CASCADE;

-- ─── Additional: Add missing indexes for common queries ───
-- Table: posts exists with (world_id, created_at)
CREATE INDEX IF NOT EXISTS idx_posts_world_created ON public.posts(world_id, created_at DESC);

-- Table: channel_messages (NOT messages - that table doesn't exist)
CREATE INDEX IF NOT EXISTS idx_channel_messages_channel_created ON public.channel_messages(channel_id, created_at DESC);

-- Table: chat_messages
CREATE INDEX IF NOT EXISTS idx_chat_messages_room_created ON public.chat_messages(room_id, created_at DESC);

-- Table: notifications (column is "read" not "read_at" - use created_at for unread ordering)
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_unread ON public.notifications(recipient_id, read, created_at DESC) WHERE read = false;

-- Table: verification_submissions
CREATE INDEX IF NOT EXISTS idx_verification_submissions_status ON public.verification_submissions(status);

-- ─── Additional: Add updated_at trigger for posts ───
-- Table: posts has created_at but no updated_at column — add it first
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_posts_updated_at ON public.posts;
CREATE TRIGGER set_posts_updated_at
  BEFORE UPDATE ON public.posts
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();
