-- Add auto_delete_after_seconds column to chat_messages for auto-deleting DMs
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS auto_delete_after_seconds INT;

-- Add index for efficient cleanup queries
CREATE INDEX IF NOT EXISTS idx_chat_messages_auto_delete ON chat_messages (created_at, auto_delete_after_seconds)
WHERE auto_delete_after_seconds IS NOT NULL;
