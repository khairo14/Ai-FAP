-- Add carry_forward flag to budgets table.
-- When true, any unspent amount from the previous period is rolled over
-- and added to the current period's effective budget limit.

ALTER TABLE budgets
  ADD COLUMN IF NOT EXISTS carry_forward boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN budgets.carry_forward IS
  'When true, unspent budget from the previous period is added to the current period limit.';
