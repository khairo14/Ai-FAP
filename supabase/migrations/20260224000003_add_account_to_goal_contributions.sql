-- Track which account a goal contribution came from (deposit) or went to (withdrawal)
ALTER TABLE goal_contributions
  ADD COLUMN IF NOT EXISTS account_id UUID REFERENCES accounts(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_goal_contributions_account
  ON goal_contributions (account_id)
  WHERE account_id IS NOT NULL;
