-- ─────────────────────────────────────────────────────────────────────────────
-- Phase 4: Debt Management
-- debts table — tracks individual debts (credit cards, loans, etc.)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS debts (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  name             TEXT NOT NULL,
  description      TEXT,

  -- 'credit_card' | 'student_loan' | 'mortgage' | 'car_loan' | 'personal_loan' | 'medical' | 'other'
  debt_type        TEXT NOT NULL DEFAULT 'other'
                     CHECK (debt_type IN ('credit_card', 'student_loan', 'mortgage',
                                          'car_loan', 'personal_loan', 'medical', 'other')),

  total_amount     NUMERIC(15,2) NOT NULL CHECK (total_amount > 0),   -- original balance
  current_balance  NUMERIC(15,2) NOT NULL CHECK (current_balance >= 0), -- remaining balance

  interest_rate    NUMERIC(7,4) NOT NULL DEFAULT 0                    -- annual %, e.g. 18.99
                     CHECK (interest_rate >= 0 AND interest_rate <= 100),

  minimum_payment  NUMERIC(15,2) NOT NULL DEFAULT 0 CHECK (minimum_payment >= 0),
  payment_due_day  SMALLINT CHECK (payment_due_day BETWEEN 1 AND 31), -- day of month

  currency         TEXT NOT NULL DEFAULT 'USD',

  -- Icon/colour for UI
  icon             TEXT,
  color            TEXT,

  is_paid_off      BOOLEAN NOT NULL DEFAULT FALSE,
  paid_off_at      TIMESTAMPTZ,

  notes            TEXT,

  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at       TIMESTAMPTZ
);

-- ── RLS ──────────────────────────────────────────────────────────────────────
ALTER TABLE debts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own debts"
  ON debts FOR ALL
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ── Indexes ───────────────────────────────────────────────────────────────────
CREATE INDEX idx_debts_user_active
  ON debts (user_id, is_paid_off)
  WHERE deleted_at IS NULL;

-- ── Updated-at trigger ────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_debts_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

CREATE TRIGGER trg_debts_updated_at
  BEFORE UPDATE ON debts
  FOR EACH ROW EXECUTE FUNCTION update_debts_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- debt_payments — payment history for each debt
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS debt_payments (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  debt_id     UUID NOT NULL REFERENCES debts(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount      NUMERIC(15,2) NOT NULL CHECK (amount > 0),
  notes       TEXT,
  paid_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE debt_payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own debt payments"
  ON debt_payments FOR ALL
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_debt_payments_debt
  ON debt_payments (debt_id, paid_at DESC);

-- ── Trigger: reduce debts.current_balance after payment ──────────────────────
CREATE OR REPLACE FUNCTION apply_debt_payment()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  UPDATE debts
  SET current_balance = GREATEST(0, current_balance - NEW.amount),
      is_paid_off     = (GREATEST(0, current_balance - NEW.amount) = 0),
      paid_off_at     = CASE
                          WHEN GREATEST(0, current_balance - NEW.amount) = 0
                          THEN now() ELSE paid_off_at
                        END,
      updated_at      = now()
  WHERE id = NEW.debt_id;
  RETURN NEW;
END; $$;

CREATE TRIGGER trg_apply_debt_payment
  AFTER INSERT ON debt_payments
  FOR EACH ROW EXECUTE FUNCTION apply_debt_payment();
