-- Migration: Add tags column to expenses and income
-- Allows users to attach freeform tags (e.g. #work, #trip-bali) to any
-- expense or income entry for cross-category grouping and filtering.
--
-- Uses a native Postgres text[] array so no join table is needed.
-- Default is an empty array so existing rows are unaffected.

ALTER TABLE expenses
  ADD COLUMN IF NOT EXISTS tags text[] NOT NULL DEFAULT '{}';

CREATE INDEX IF NOT EXISTS idx_expenses_tags ON expenses USING GIN (tags);

ALTER TABLE income
  ADD COLUMN IF NOT EXISTS tags text[] NOT NULL DEFAULT '{}';

CREATE INDEX IF NOT EXISTS idx_income_tags ON income USING GIN (tags);
