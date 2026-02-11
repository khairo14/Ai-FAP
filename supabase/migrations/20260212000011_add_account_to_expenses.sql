-- Migration 011: Add Account Integration to Expenses
-- Description: Add account_id field to expenses table for tracking account-specific transactions
-- Date: February 12, 2026

-- Add account_id column to expenses table
ALTER TABLE expenses 
ADD COLUMN account_id UUID REFERENCES accounts(id) ON DELETE SET NULL;

-- Create index for better performance on account queries
CREATE INDEX idx_expenses_account_id ON expenses(account_id);

-- Update RLS policies to include account context (optional - expenses can be without account)
-- No RLS changes needed as account_id is optional

-- Add helpful comment
COMMENT ON COLUMN expenses.account_id IS 'Optional reference to the account this expense was paid from';