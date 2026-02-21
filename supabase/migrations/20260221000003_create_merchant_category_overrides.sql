-- ─────────────────────────────────────────────────────────────────────────────
-- Phase 3: Personalization Engine
-- merchant_category_overrides
--   Stores user-specific merchant → category mappings learned from corrections.
--   When a user manually changes the auto-suggested category for a merchant the
--   override is saved here and applied on the next expense entry for that merchant.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS merchant_category_overrides (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  merchant_normalized TEXT NOT NULL,          -- lowercase, stripped to [a-z0-9 ]
  category_id        UUID NOT NULL REFERENCES expense_categories(id) ON DELETE CASCADE,
  use_count          INTEGER NOT NULL DEFAULT 1,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (user_id, merchant_normalized)       -- one override per merchant per user
);

-- ── RLS ──────────────────────────────────────────────────────────────────────
ALTER TABLE merchant_category_overrides ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own overrides"
  ON merchant_category_overrides
  FOR ALL
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ── Indexes ───────────────────────────────────────────────────────────────────
CREATE INDEX idx_overrides_user_merchant
  ON merchant_category_overrides (user_id, merchant_normalized);

-- ── Updated-at trigger ────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_merchant_override_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_merchant_override_updated_at
  BEFORE UPDATE ON merchant_category_overrides
  FOR EACH ROW EXECUTE FUNCTION update_merchant_override_updated_at();
