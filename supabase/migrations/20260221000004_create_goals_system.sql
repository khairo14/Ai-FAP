-- ─────────────────────────────────────────────────────────────────────────────
-- Phase 4: Goal Planner
-- goals table — tracks savings goals, debt payoff goals, and purchase goals
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS goals (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  title           TEXT NOT NULL,
  description     TEXT,

  -- 'savings' | 'debt_payoff' | 'purchase' | 'emergency_fund' | 'investment'
  goal_type       TEXT NOT NULL DEFAULT 'savings'
                    CHECK (goal_type IN ('savings', 'debt_payoff', 'purchase',
                                        'emergency_fund', 'investment')),

  target_amount   NUMERIC(15,2) NOT NULL CHECK (target_amount > 0),
  current_amount  NUMERIC(15,2) NOT NULL DEFAULT 0 CHECK (current_amount >= 0),

  currency        TEXT NOT NULL DEFAULT 'USD',
  target_date     DATE,

  -- Icon/colour for the UI
  icon            TEXT,
  color           TEXT,

  is_completed    BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at    TIMESTAMPTZ,

  notes           TEXT,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at      TIMESTAMPTZ
);

-- ── RLS ──────────────────────────────────────────────────────────────────────
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own goals"
  ON goals FOR ALL
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ── Indexes ───────────────────────────────────────────────────────────────────
CREATE INDEX idx_goals_user_active
  ON goals (user_id, is_completed)
  WHERE deleted_at IS NULL;

-- ── Updated-at trigger ────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_goals_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

CREATE TRIGGER trg_goals_updated_at
  BEFORE UPDATE ON goals
  FOR EACH ROW EXECUTE FUNCTION update_goals_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- goal_contributions — manual deposits/withdrawals toward a goal
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS goal_contributions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id     UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount      NUMERIC(15,2) NOT NULL,  -- positive = deposit, negative = withdrawal
  notes       TEXT,
  contributed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE goal_contributions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own goal contributions"
  ON goal_contributions FOR ALL
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_goal_contributions_goal
  ON goal_contributions (goal_id, contributed_at DESC);

-- ── Trigger: keep goals.current_amount in sync ───────────────────────────────
CREATE OR REPLACE FUNCTION sync_goal_current_amount()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  UPDATE goals
  SET current_amount = GREATEST(0, (
        SELECT COALESCE(SUM(amount), 0)
        FROM goal_contributions
        WHERE goal_id = COALESCE(NEW.goal_id, OLD.goal_id)
      )),
      updated_at = now()
  WHERE id = COALESCE(NEW.goal_id, OLD.goal_id);
  RETURN NEW;
END; $$;

CREATE TRIGGER trg_sync_goal_amount
  AFTER INSERT OR UPDATE OR DELETE ON goal_contributions
  FOR EACH ROW EXECUTE FUNCTION sync_goal_current_amount();
