-- Add recurring_frequency column to expenses table
-- Stores how often a recurring expense repeats

ALTER TABLE expenses
  ADD COLUMN IF NOT EXISTS recurring_frequency TEXT
    CHECK (recurring_frequency IN ('daily', 'weekly', 'bi-weekly', 'monthly', 'yearly'));

-- Index for querying recurring expenses efficiently
CREATE INDEX IF NOT EXISTS idx_expenses_recurring
  ON expenses (user_id, is_recurring)
  WHERE is_recurring = TRUE AND deleted_at IS NULL;

COMMENT ON COLUMN expenses.recurring_frequency IS
  'Frequency of recurrence: daily, weekly, bi-weekly, monthly, yearly. Only set when is_recurring = true.';
