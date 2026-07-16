-- Allow reporting a resident (profile) without a post/message target.
ALTER TABLE public.reports
  ADD COLUMN IF NOT EXISTS reported_resident_id TEXT;

ALTER TABLE public.reports
  DROP CONSTRAINT IF EXISTS reports_target_check;

ALTER TABLE public.reports
  ADD CONSTRAINT reports_target_check
  CHECK (
    post_id IS NOT NULL
    OR message_id IS NOT NULL
    OR world_id IS NOT NULL
    OR reported_resident_id IS NOT NULL
  );

CREATE INDEX IF NOT EXISTS idx_reports_reported_resident
  ON public.reports(reported_resident_id)
  WHERE reported_resident_id IS NOT NULL;
