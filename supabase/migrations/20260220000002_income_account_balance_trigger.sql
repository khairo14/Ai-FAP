-- Migration: Income Account Balance Triggers + Make account_id required
-- Description: When income is added to an account, the account balance increases by net_amount.
--              Mirrors the expense trigger pattern (but adds instead of subtracts).
-- Date: February 20, 2026

-- Make account_id NOT NULL (all income must belong to an account)
ALTER TABLE income ALTER COLUMN account_id SET NOT NULL;

-- Drop any existing triggers
DROP TRIGGER IF EXISTS income_insert_update_account ON income;
DROP TRIGGER IF EXISTS income_update_update_account ON income;
DROP TRIGGER IF EXISTS income_soft_delete_update_account ON income;
DROP TRIGGER IF EXISTS income_restore_update_account ON income;
DROP TRIGGER IF EXISTS income_delete_update_account ON income;

-- ── INSERT: add net_amount to account balance ──────────────────────────────────
CREATE OR REPLACE FUNCTION update_account_on_income_insert()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE accounts
    SET current_balance    = current_balance + NEW.net_amount,
        available_balance  = GREATEST(0, current_balance + NEW.net_amount - COALESCE(credit_used, 0)),
        last_transaction_date = NOW(),
        updated_at         = NOW()
    WHERE id      = NEW.account_id
      AND user_id = NEW.user_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ── UPDATE: handle account change or amount change ────────────────────────────
CREATE OR REPLACE FUNCTION update_account_on_income_update()
RETURNS TRIGGER AS $$
DECLARE
    net_diff DECIMAL;
BEGIN
    IF OLD.account_id IS DISTINCT FROM NEW.account_id THEN
        -- Revert old account (remove income that was credited there)
        UPDATE accounts
        SET current_balance   = current_balance - OLD.net_amount,
            available_balance = GREATEST(0, current_balance - OLD.net_amount - COALESCE(credit_used, 0)),
            updated_at        = NOW()
        WHERE id      = OLD.account_id
          AND user_id = OLD.user_id;

        -- Credit new account
        UPDATE accounts
        SET current_balance    = current_balance + NEW.net_amount,
            available_balance  = GREATEST(0, current_balance + NEW.net_amount - COALESCE(credit_used, 0)),
            last_transaction_date = NOW(),
            updated_at         = NOW()
        WHERE id      = NEW.account_id
          AND user_id = NEW.user_id;

    ELSIF OLD.net_amount IS DISTINCT FROM NEW.net_amount THEN
        -- Same account, different amount — apply the difference
        net_diff := NEW.net_amount - OLD.net_amount;

        UPDATE accounts
        SET current_balance    = current_balance + net_diff,
            available_balance  = GREATEST(0, current_balance + net_diff - COALESCE(credit_used, 0)),
            last_transaction_date = NOW(),
            updated_at         = NOW()
        WHERE id      = NEW.account_id
          AND user_id = NEW.user_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ── SOFT DELETE: reverse the income (remove from balance) ─────────────────────
CREATE OR REPLACE FUNCTION update_account_on_income_delete()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE accounts
    SET current_balance   = current_balance - OLD.net_amount,
        available_balance = GREATEST(0, current_balance - OLD.net_amount - COALESCE(credit_used, 0)),
        updated_at        = NOW()
    WHERE id      = OLD.account_id
      AND user_id = OLD.user_id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- ── RESTORE: re-credit the account when income is un-deleted ──────────────────
CREATE OR REPLACE FUNCTION update_account_on_income_restore()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE accounts
    SET current_balance    = current_balance + NEW.net_amount,
        available_balance  = GREATEST(0, current_balance + NEW.net_amount - COALESCE(credit_used, 0)),
        last_transaction_date = NOW(),
        updated_at         = NOW()
    WHERE id      = NEW.account_id
      AND user_id = NEW.user_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ── Attach triggers ───────────────────────────────────────────────────────────
CREATE TRIGGER income_insert_update_account
    AFTER INSERT ON income
    FOR EACH ROW
    EXECUTE FUNCTION update_account_on_income_insert();

CREATE TRIGGER income_update_update_account
    AFTER UPDATE OF account_id, net_amount ON income
    FOR EACH ROW
    EXECUTE FUNCTION update_account_on_income_update();

-- Soft delete: deleted_at goes from NULL → timestamp
CREATE TRIGGER income_soft_delete_update_account
    AFTER UPDATE OF deleted_at ON income
    FOR EACH ROW
    WHEN (OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL)
    EXECUTE FUNCTION update_account_on_income_delete();

-- Restore: deleted_at goes from timestamp → NULL
CREATE TRIGGER income_restore_update_account
    AFTER UPDATE OF deleted_at ON income
    FOR EACH ROW
    WHEN (OLD.deleted_at IS NOT NULL AND NEW.deleted_at IS NULL)
    EXECUTE FUNCTION update_account_on_income_restore();

-- Hard delete
CREATE TRIGGER income_delete_update_account
    AFTER DELETE ON income
    FOR EACH ROW
    EXECUTE FUNCTION update_account_on_income_delete();
