-- Run this in the Supabase SQL editor first

CREATE TABLE journal_entries (
  id                UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id           UUID        REFERENCES auth.users(id) ON DELETE CASCADE,
  mood              TEXT,
  emotions          TEXT[],
  context_answer_1  TEXT,
  context_answer_2  TEXT,
  free_write        TEXT,
  mode              TEXT,
  ai_response_json  JSONB,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_journal_entries_user_id    ON journal_entries(user_id);
CREATE INDEX idx_journal_entries_created_at ON journal_entries(created_at DESC);
