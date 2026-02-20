-- ================================================================================================
-- Migration: Fix per-account currency override
-- Description: Add currency_manually_set flag to prevent profile currency changes from overriding manually-set account currencies
-- Date: February 14, 2026
-- ================================================================================================

-- Add currency_manually_set field to accounts table
ALTER TABLE accounts 
ADD COLUMN IF NOT EXISTS currency_manually_set BOOLEAN DEFAULT false;

-- Add comment
COMMENT ON COLUMN accounts.currency_manually_set IS 
'Indicates if the account currency has been manually set by the user and should not be auto-updated when profile currency changes';

-- Update the function to respect the manually_set flag
CREATE OR REPLACE FUNCTION update_account_currencies()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Only update if currency actually changed
    IF OLD.currency IS DISTINCT FROM NEW.currency THEN
        -- Only update accounts that:
        -- 1. Still match the OLD currency
        -- 2. Have NOT been manually set to a different currency
        UPDATE accounts
        SET currency = NEW.currency,
            updated_at = NOW()
        WHERE user_id = NEW.id
          AND currency = OLD.currency  -- Only update accounts with the old currency
          AND currency_manually_set = false  -- Only update accounts not manually set
          AND deleted_at IS NULL;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Trigger to set currency_manually_set flag when currency is explicitly updated
CREATE OR REPLACE FUNCTION mark_currency_manually_set()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN
    -- If currency is being changed (and it's not the initial creation)
    IF TG_OP = 'UPDATE' AND OLD.currency IS DISTINCT FROM NEW.currency THEN
        -- Check if this update is coming from the profile currency update trigger
        -- by checking if the new currency matches the user's profile currency
        DECLARE
            v_profile_currency TEXT;
        BEGIN
            SELECT currency INTO v_profile_currency FROM profiles WHERE id = NEW.user_id;
            
            -- If the new currency is different from profile currency, it's a manual change
            IF NEW.currency IS DISTINCT FROM v_profile_currency THEN
                NEW.currency_manually_set := true;
            ELSE
                -- If changing to profile currency, it's likely intentional so keep the manual flag
                -- unless it was already false
                IF OLD.currency_manually_set = false THEN
                    NEW.currency_manually_set := false;
                END IF;
            END IF;
        END;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger to mark currency as manually set
DROP TRIGGER IF EXISTS mark_currency_manually_set_trigger ON accounts;
CREATE TRIGGER mark_currency_manually_set_trigger
    BEFORE UPDATE ON accounts
    FOR EACH ROW
    WHEN (OLD.currency IS DISTINCT FROM NEW.currency)
    EXECUTE FUNCTION mark_currency_manually_set();

-- Add comment
COMMENT ON FUNCTION mark_currency_manually_set() IS 
'Automatically sets currency_manually_set flag to true when an account currency is manually changed to a value different from the profile currency';
