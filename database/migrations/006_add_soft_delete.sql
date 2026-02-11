-- Migration 006: Add Soft Delete Support
-- Description: Add deleted_at column to expenses and budgets for soft delete functionality
-- Date: February 12, 2026

-- Add deleted_at column to expenses table
ALTER TABLE expenses 
ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE;

-- Add deleted_at column to budgets table
ALTER TABLE budgets 
ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE;

-- Create index for efficient filtering of non-deleted records
CREATE INDEX idx_expenses_deleted_at ON expenses(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_budgets_deleted_at ON budgets(deleted_at) WHERE deleted_at IS NULL;

-- Verify the changes
SELECT 
  table_name,
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns
WHERE table_name IN ('expenses', 'budgets') 
  AND column_name = 'deleted_at';

-- Check indexes
SELECT 
  tablename, 
  indexname, 
  indexdef
FROM pg_indexes
WHERE tablename IN ('expenses', 'budgets')
  AND indexname LIKE '%deleted%';
