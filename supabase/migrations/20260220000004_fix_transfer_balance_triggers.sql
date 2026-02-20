-- Migration: Fix Transfer Balance Triggers
-- Description: Remove SECURITY DEFINER so auth.uid() works inside triggers,
--              add user_id filter matching the working expense trigger pattern.
-- Date: February 20, 2026

-- ─── INSERT ──────────────────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS trigger_update_account_on_transfer_insert ON transfers;
DROP FUNCTION IF EXISTS update_account_on_transfer_insert();

CREATE OR REPLACE FUNCTION update_account_on_transfer_insert()
RETURNS TRIGGER AS $$
BEGIN
  -- Deduct from source account (amount + fee)
  UPDATE accounts
  SET current_balance = current_balance - (NEW.from_amount + COALESCE(NEW.transfer_fee, 0)),
      available_balance = GREATEST(0, current_balance - (NEW.from_amount + COALESCE(NEW.transfer_fee, 0)) - COALESCE(credit_used, 0)),
      last_transaction_date = NOW(),
      updated_at = NOW()
  WHERE id = NEW.from_account_id
    AND user_id = NEW.user_id;

  -- Add to destination account
  UPDATE accounts
  SET current_balance = current_balance + NEW.to_amount,
      available_balance = GREATEST(0, current_balance + NEW.to_amount - COALESCE(credit_used, 0)),
      last_transaction_date = NOW(),
      updated_at = NOW()
  WHERE id = NEW.to_account_id
    AND user_id = NEW.user_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_account_on_transfer_insert
  AFTER INSERT ON transfers
  FOR EACH ROW
  EXECUTE FUNCTION update_account_on_transfer_insert();

-- ─── SOFT DELETE ─────────────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS trigger_update_account_on_transfer_soft_delete ON transfers;
DROP FUNCTION IF EXISTS update_account_on_transfer_soft_delete();

CREATE OR REPLACE FUNCTION update_account_on_transfer_soft_delete()
RETURNS TRIGGER AS $$
BEGIN
  -- Restore source account
  UPDATE accounts
  SET current_balance = current_balance + (OLD.from_amount + COALESCE(OLD.transfer_fee, 0)),
      available_balance = GREATEST(0, current_balance + (OLD.from_amount + COALESCE(OLD.transfer_fee, 0)) - COALESCE(credit_used, 0)),
      updated_at = NOW()
  WHERE id = OLD.from_account_id
    AND user_id = OLD.user_id;

  -- Restore destination account
  UPDATE accounts
  SET current_balance = current_balance - OLD.to_amount,
      available_balance = GREATEST(0, current_balance - OLD.to_amount - COALESCE(credit_used, 0)),
      updated_at = NOW()
  WHERE id = OLD.to_account_id
    AND user_id = OLD.user_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_account_on_transfer_soft_delete
  AFTER UPDATE OF deleted_at ON transfers
  FOR EACH ROW
  WHEN (OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL)
  EXECUTE FUNCTION update_account_on_transfer_soft_delete();

-- ─── HARD DELETE ─────────────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS trigger_update_account_on_transfer_delete ON transfers;
DROP FUNCTION IF EXISTS update_account_on_transfer_delete();

CREATE OR REPLACE FUNCTION update_account_on_transfer_delete()
RETURNS TRIGGER AS $$
BEGIN
  -- Restore source account
  UPDATE accounts
  SET current_balance = current_balance + (OLD.from_amount + COALESCE(OLD.transfer_fee, 0)),
      available_balance = GREATEST(0, current_balance + (OLD.from_amount + COALESCE(OLD.transfer_fee, 0)) - COALESCE(credit_used, 0)),
      updated_at = NOW()
  WHERE id = OLD.from_account_id
    AND user_id = OLD.user_id;

  -- Restore destination account
  UPDATE accounts
  SET current_balance = current_balance - OLD.to_amount,
      available_balance = GREATEST(0, current_balance - OLD.to_amount - COALESCE(credit_used, 0)),
      updated_at = NOW()
  WHERE id = OLD.to_account_id
    AND user_id = OLD.user_id;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_account_on_transfer_delete
  AFTER DELETE ON transfers
  FOR EACH ROW
  EXECUTE FUNCTION update_account_on_transfer_delete();
