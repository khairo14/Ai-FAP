-- Migration: Transfer Balance Triggers
-- Description: Auto-update account balances when transfers are inserted/deleted
-- Date: February 20, 2026

-- ─── INSERT: deduct from source, add to destination ───────────────────────────
CREATE OR REPLACE FUNCTION update_account_on_transfer_insert()
RETURNS TRIGGER AS $$
BEGIN
  -- Deduct from source account (amount + fee)
  UPDATE accounts
  SET current_balance = current_balance - (NEW.from_amount + COALESCE(NEW.transfer_fee, 0)),
      updated_at = NOW()
  WHERE id = NEW.from_account_id;

  -- Add to destination account
  UPDATE accounts
  SET current_balance = current_balance + NEW.to_amount,
      updated_at = NOW()
  WHERE id = NEW.to_account_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── HARD DELETE: restore both account balances ───────────────────────────────
CREATE OR REPLACE FUNCTION update_account_on_transfer_delete()
RETURNS TRIGGER AS $$
BEGIN
  -- Restore source account
  UPDATE accounts
  SET current_balance = current_balance + (OLD.from_amount + COALESCE(OLD.transfer_fee, 0)),
      updated_at = NOW()
  WHERE id = OLD.from_account_id;

  -- Restore destination account
  UPDATE accounts
  SET current_balance = current_balance - OLD.to_amount,
      updated_at = NOW()
  WHERE id = OLD.to_account_id;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── SOFT DELETE: same as hard delete (restore balances) ─────────────────────
CREATE OR REPLACE FUNCTION update_account_on_transfer_soft_delete()
RETURNS TRIGGER AS $$
BEGIN
  -- Restore source account
  UPDATE accounts
  SET current_balance = current_balance + (OLD.from_amount + COALESCE(OLD.transfer_fee, 0)),
      updated_at = NOW()
  WHERE id = OLD.from_account_id;

  -- Restore destination account
  UPDATE accounts
  SET current_balance = current_balance - OLD.to_amount,
      updated_at = NOW()
  WHERE id = OLD.to_account_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── ATTACH TRIGGERS ─────────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS trigger_update_account_on_transfer_insert ON transfers;
CREATE TRIGGER trigger_update_account_on_transfer_insert
  AFTER INSERT ON transfers
  FOR EACH ROW
  EXECUTE FUNCTION update_account_on_transfer_insert();

DROP TRIGGER IF EXISTS trigger_update_account_on_transfer_delete ON transfers;
CREATE TRIGGER trigger_update_account_on_transfer_delete
  AFTER DELETE ON transfers
  FOR EACH ROW
  EXECUTE FUNCTION update_account_on_transfer_delete();

DROP TRIGGER IF EXISTS trigger_update_account_on_transfer_soft_delete ON transfers;
CREATE TRIGGER trigger_update_account_on_transfer_soft_delete
  AFTER UPDATE OF deleted_at ON transfers
  FOR EACH ROW
  WHEN (OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL)
  EXECUTE FUNCTION update_account_on_transfer_soft_delete();
