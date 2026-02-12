-- ================================================================================================
-- Migration: Add default accounts for new users
-- Description: Creates default accounts for all account types when user signs up
-- ================================================================================================

-- Function to create default accounts for a new user
CREATE OR REPLACE FUNCTION create_default_accounts()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_account_type RECORD;
    v_user_currency TEXT;
    v_account_name TEXT;
    v_description TEXT;
BEGIN
    -- Get user's default currency (defaults to USD if not set)
    v_user_currency := COALESCE(NEW.currency, 'USD');
    
    -- Create accounts for all active account types
    FOR v_account_type IN 
        SELECT id, code, name, description, category 
        FROM account_types 
        WHERE is_active = true
        ORDER BY category, name
    LOOP
        -- Set account name based on type
        v_account_name := v_account_type.name;
        v_description := v_account_type.description;
        
        -- Create account
        INSERT INTO accounts (
            id, user_id, account_type_id, name, currency,
            initial_balance, current_balance, available_balance,
            description, is_active, include_in_total, created_at, updated_at
        ) VALUES (
            gen_random_uuid(),
            NEW.id,
            v_account_type.id,
            v_account_name,
            v_user_currency,
            0.00,
            0.00,
            0.00,
            v_description,
            true,
            true,
            NOW(),
            NOW()
        );
    END LOOP;

    RETURN NEW;
END;
$$;

-- Trigger to automatically create default accounts when profile is created
DROP TRIGGER IF EXISTS create_default_accounts_trigger ON profiles;
CREATE TRIGGER create_default_accounts_trigger
    AFTER INSERT ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION create_default_accounts();

-- Function to update all account currencies when profile currency changes
CREATE OR REPLACE FUNCTION update_account_currencies()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Only update if currency actually changed
    IF OLD.currency IS DISTINCT FROM NEW.currency THEN
        -- Only update accounts that still match the OLD currency
        -- This preserves accounts that users manually changed to different currencies
        UPDATE accounts
        SET currency = NEW.currency,
            updated_at = NOW()
        WHERE user_id = NEW.id
          AND currency = OLD.currency  -- Only update accounts with the old currency
          AND deleted_at IS NULL;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Trigger to update account currencies when profile currency changes
DROP TRIGGER IF EXISTS update_account_currencies_trigger ON profiles;
CREATE TRIGGER update_account_currencies_trigger
    AFTER UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_account_currencies();

-- Add comments
COMMENT ON FUNCTION create_default_accounts() IS 
'Automatically creates accounts for all active account types when new users sign up, using their profile currency. Accounts are created with zero balance and can be customized later.';

COMMENT ON FUNCTION update_account_currencies() IS 
'Automatically updates account currencies when profile currency changes, but only for accounts that still use the old currency. Accounts manually set to different currencies are preserved.';
