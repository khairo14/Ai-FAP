-- Add recurring scheduler fields to expenses, income, and debts
-- These columns power the RecurringSchedulerService that auto-creates
-- expense/income entries on a schedule and sends debt payment reminders.

-- ── Expenses ─────────────────────────────────────────────────────────────────
ALTER TABLE expenses
  ADD COLUMN IF NOT EXISTS last_auto_created_at  timestamptz,
  ADD COLUMN IF NOT EXISTS is_paused             boolean     NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS recurring_end_date    date;

-- ── Income ────────────────────────────────────────────────────────────────────
ALTER TABLE income_records
  ADD COLUMN IF NOT EXISTS last_auto_created_at  timestamptz,
  ADD COLUMN IF NOT EXISTS is_paused             boolean     NOT NULL DEFAULT false;

-- ── Debts ─────────────────────────────────────────────────────────────────────
ALTER TABLE debts
  ADD COLUMN IF NOT EXISTS payment_reminder_days  integer     NOT NULL DEFAULT 3,
  ADD COLUMN IF NOT EXISTS auto_log_payment       boolean     NOT NULL DEFAULT false;

-- Indexes for scheduler queries (only scans recurring, non-paused, non-deleted rows)
CREATE INDEX IF NOT EXISTS expenses_recurring_scheduler_idx
  ON expenses (user_id, is_recurring, is_paused, last_auto_created_at)
  WHERE is_recurring = true
    AND is_paused    = false
    AND deleted_at   IS NULL;

CREATE INDEX IF NOT EXISTS income_recurring_scheduler_idx
  ON income_records (user_id, is_recurring, is_paused, next_occurrence)
  WHERE is_recurring = true
    AND is_paused    = false
    AND deleted_at   IS NULL;

CREATE INDEX IF NOT EXISTS debts_reminder_idx
  ON debts (user_id, payment_due_day)
  WHERE is_paid_off = false
    AND deleted_at  IS NULL;
