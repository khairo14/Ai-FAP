-- Migration: Add FX fields to income table
-- Description: Supports cross-currency income entry. When a user records income
-- in a different currency from the account, we store the original amount and
-- the exchange rate used. The `amount` and `net_amount` saved to the DB are
-- always in the account's currency (so the existing balance trigger stays correct).
-- Date: February 26, 2026

ALTER TABLE income
  ADD COLUMN IF NOT EXISTS original_amount  DECIMAL(15,2),
  ADD COLUMN IF NOT EXISTS original_currency VARCHAR(3),
  ADD COLUMN IF NOT EXISTS exchange_rate     DECIMAL(18,6);

COMMENT ON COLUMN income.original_amount   IS 'Amount entered by user in their chosen currency (before conversion)';
COMMENT ON COLUMN income.original_currency IS 'Currency chosen by user when recording income';
COMMENT ON COLUMN income.exchange_rate     IS 'Exchange rate used: 1 original_currency = exchange_rate account_currency';
