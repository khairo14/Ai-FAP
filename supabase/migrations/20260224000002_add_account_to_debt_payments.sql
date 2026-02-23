-- Track which account a debt payment was made from
ALTER TABLE debt_payments
  ADD COLUMN IF NOT EXISTS account_id UUID REFERENCES accounts(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_debt_payments_account
  ON debt_payments (account_id)
  WHERE account_id IS NOT NULL;
