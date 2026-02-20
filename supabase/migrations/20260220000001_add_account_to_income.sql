-- Migration: Add account_id to income table
-- Description: Allow income to be linked to a specific account
-- Date: February 20, 2026

ALTER TABLE income
  ADD COLUMN IF NOT EXISTS account_id UUID REFERENCES accounts(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_income_account_id ON income(account_id);
