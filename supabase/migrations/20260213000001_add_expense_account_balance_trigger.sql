-- Migration: Add Account Balance Update Triggers for Expenses
-- Description: Automatically update account balances when expenses are created/updated/deleted
-- Date: February 13, 2026

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS expense_insert_update_account ON expenses;
DROP TRIGGER IF EXISTS expense_update_update_account ON expenses;
DROP TRIGGER IF EXISTS expense_soft_delete_update_account ON expenses;
DROP TRIGGER IF EXISTS expense_delete_update_account ON expenses;

-- Function to update account balance when expense is inserted
CREATE OR REPLACE FUNCTION update_account_on_expense_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- Only update if account_id is provided
    IF NEW.account_id IS NOT NULL THEN
        -- Subtract expense amount from account balance
        UPDATE accounts 
        SET current_balance = current_balance - NEW.amount,
            available_balance = GREATEST(0, current_balance - NEW.amount - COALESCE(credit_used, 0)),
            last_transaction_date = NOW(),
            updated_at = NOW()
        WHERE id = NEW.account_id
            AND user_id = NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update account balance when expense is updated
CREATE OR REPLACE FUNCTION update_account_on_expense_update()
RETURNS TRIGGER AS $$
DECLARE
    amount_diff DECIMAL;
BEGIN
    -- If account changed, revert old account and update new account
    IF OLD.account_id IS DISTINCT FROM NEW.account_id THEN
        -- Revert old account balance
        IF OLD.account_id IS NOT NULL THEN
            UPDATE accounts 
            SET current_balance = current_balance + OLD.amount,
                available_balance = GREATEST(0, current_balance + OLD.amount - COALESCE(credit_used, 0)),
                updated_at = NOW()
            WHERE id = OLD.account_id
                AND user_id = OLD.user_id;
        END IF;
        
        -- Update new account balance
        IF NEW.account_id IS NOT NULL THEN
            UPDATE accounts 
            SET current_balance = current_balance - NEW.amount,
                available_balance = GREATEST(0, current_balance - NEW.amount - COALESCE(credit_used, 0)),
                last_transaction_date = NOW(),
                updated_at = NOW()
            WHERE id = NEW.account_id
                AND user_id = NEW.user_id;
        END IF;
    -- If only amount changed on same account
    ELSIF OLD.amount != NEW.amount AND NEW.account_id IS NOT NULL THEN
        -- Calculate the difference and adjust
        amount_diff := NEW.amount - OLD.amount;
        
        UPDATE accounts 
        SET current_balance = current_balance - amount_diff,
            available_balance = GREATEST(0, current_balance - amount_diff - COALESCE(credit_used, 0)),
            last_transaction_date = NOW(),
            updated_at = NOW()
        WHERE id = NEW.account_id
            AND user_id = NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update account balance when expense is deleted
CREATE OR REPLACE FUNCTION update_account_on_expense_delete()
RETURNS TRIGGER AS $$
BEGIN
    -- Only update if account_id is provided
    IF OLD.account_id IS NOT NULL THEN
        -- Add expense amount back to account balance (soft delete scenario)
        UPDATE accounts 
        SET current_balance = current_balance + OLD.amount,
            available_balance = GREATEST(0, current_balance + OLD.amount - COALESCE(credit_used, 0)),
            updated_at = NOW()
        WHERE id = OLD.account_id
            AND user_id = OLD.user_id;
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER expense_insert_update_account
    AFTER INSERT ON expenses
    FOR EACH ROW
    EXECUTE FUNCTION update_account_on_expense_insert();

CREATE TRIGGER expense_update_update_account
    AFTER UPDATE ON expenses
    FOR EACH ROW
    EXECUTE FUNCTION update_account_on_expense_update();

-- Trigger for soft delete (when deleted_at is set)
CREATE TRIGGER expense_soft_delete_update_account
    AFTER UPDATE OF deleted_at ON expenses
    FOR EACH ROW
    WHEN (OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL)
    EXECUTE FUNCTION update_account_on_expense_delete();

-- Trigger for permanent delete
CREATE TRIGGER expense_delete_update_account
    AFTER DELETE ON expenses
    FOR EACH ROW
    EXECUTE FUNCTION update_account_on_expense_delete();

-- Add comment
COMMENT ON FUNCTION update_account_on_expense_insert() IS 'Automatically deducts expense amount from account balance on insert';
COMMENT ON FUNCTION update_account_on_expense_update() IS 'Automatically adjusts account balance when expense is updated';
COMMENT ON FUNCTION update_account_on_expense_delete() IS 'Automatically restores expense amount to account balance on delete';
