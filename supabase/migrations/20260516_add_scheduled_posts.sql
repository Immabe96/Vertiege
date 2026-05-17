-- Add scheduled_for column to posts table for scheduled post publishing
ALTER TABLE posts ADD COLUMN IF NOT EXISTS scheduled_for TIMESTAMPTZ;

-- Add index for efficient querying of posts ready to publish
CREATE INDEX IF NOT EXISTS idx_posts_scheduled_for ON posts (scheduled_for)
WHERE scheduled_for IS NOT NULL AND status = 'published';
