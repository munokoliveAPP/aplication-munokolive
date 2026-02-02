-- Add reply_to_id column for threading/replies
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS reply_to_id UUID REFERENCES chat_messages(id);

-- Add reactions column for storing emoji reactions (e.g. {"user_id": "❤️", "user_id2": "👍"})
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS reactions JSONB DEFAULT '{}'::jsonb;
