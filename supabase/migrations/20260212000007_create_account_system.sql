-- Migration 007: Create Account System
-- Description: Complete account and wallet management system
-- Date: February 12, 2026

-- Create account types table
CREATE TABLE account_types (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(50) NOT NULL,
    color VARCHAR(7) NOT NULL,
    category VARCHAR(20) NOT NULL CHECK (category IN ('bank', 'online_bank', 'wallet', 'credit', 'cash', 'crypto', 'investment')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create accounts table
CREATE TABLE accounts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    account_type_id UUID NOT NULL REFERENCES account_types(id) ON DELETE RESTRICT,
    
    -- Basic account information
    name VARCHAR(255) NOT NULL,
    description TEXT,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    
    -- Balance tracking
    initial_balance DECIMAL(15,2) DEFAULT 0,
    current_balance DECIMAL(15,2) DEFAULT 0,
    available_balance DECIMAL(15,2) DEFAULT 0,
    
    -- Account details
    institution_name VARCHAR(255),
    account_nickname VARCHAR(100),
    
    -- Credit account specific fields
    credit_limit DECIMAL(15,2),
    credit_used DECIMAL(15,2) DEFAULT 0,
    
    -- Account status and settings
    is_active BOOLEAN DEFAULT true,
    include_in_total BOOLEAN DEFAULT true,
    is_hidden BOOLEAN DEFAULT false,
    
    -- Metadata
    account_settings JSONB,
    last_transaction_date TIMESTAMP WITH TIME ZONE,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE NULL
);

-- CREATE INDEXES
CREATE INDEX idx_accounts_user_id ON accounts(user_id);
CREATE INDEX idx_accounts_type_id ON accounts(account_type_id);
CREATE INDEX idx_accounts_active ON accounts(is_active);
CREATE INDEX idx_accounts_deleted_at ON accounts(deleted_at);
CREATE INDEX idx_accounts_last_transaction ON accounts(last_transaction_date);

-- CREATE TRIGGERS
CREATE TRIGGER set_updated_at_account_types
    BEFORE UPDATE ON account_types
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_updated_at_accounts
    BEFORE UPDATE ON accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ENABLE ROW LEVEL SECURITY
ALTER TABLE account_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;

-- RLS POLICIES FOR ACCOUNT TYPES
CREATE POLICY "Users can view active account types" 
    ON account_types FOR SELECT 
    USING (is_active = true);

-- RLS POLICIES FOR ACCOUNTS
CREATE POLICY "Users can view their own accounts" 
    ON accounts FOR SELECT 
    USING (auth.uid() = user_id AND deleted_at IS NULL);

CREATE POLICY "Users can insert their own accounts" 
    ON accounts FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own accounts" 
    ON accounts FOR UPDATE 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own accounts" 
    ON accounts FOR DELETE 
    USING (auth.uid() = user_id);

-- ACCOUNT MANAGEMENT FUNCTIONS
CREATE OR REPLACE FUNCTION update_account_balance(
    account_id UUID,
    amount_change DECIMAL,
    operation VARCHAR
)
RETURNS DECIMAL AS $$
DECLARE
    new_balance DECIMAL;
BEGIN
    IF operation = 'add' THEN
        UPDATE accounts 
        SET current_balance = current_balance + amount_change,
            available_balance = GREATEST(0, current_balance + amount_change - COALESCE(credit_used, 0)),
            last_transaction_date = NOW()
        WHERE id = account_id
        RETURNING current_balance INTO new_balance;
    ELSIF operation = 'subtract' THEN
        UPDATE accounts 
        SET current_balance = current_balance - amount_change,
            available_balance = GREATEST(0, current_balance - amount_change - COALESCE(credit_used, 0)),
            last_transaction_date = NOW()
        WHERE id = account_id
        RETURNING current_balance INTO new_balance;
    END IF;
    
    RETURN new_balance;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_user_total_balance(
    user_id UUID,
    currency_filter VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    total_balance DECIMAL,
    currency VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        SUM(a.current_balance) as total_balance,
        a.currency
    FROM accounts a
    WHERE a.user_id = $1 
        AND a.is_active = true 
        AND a.include_in_total = true
        AND a.deleted_at IS NULL
        AND (currency_filter IS NULL OR a.currency = currency_filter)
    GROUP BY a.currency;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_user_accounts_summary(user_id UUID)
RETURNS TABLE(
    account_id UUID,
    account_name VARCHAR,
    account_type VARCHAR,
    current_balance DECIMAL,
    currency VARCHAR,
    is_credit BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id as account_id,
        a.name::VARCHAR as account_name,
        at.name::VARCHAR as account_type,
        a.current_balance,
        a.currency::VARCHAR,
        (at.category = 'credit') as is_credit
    FROM accounts a
    JOIN account_types at ON a.account_type_id = at.id
    WHERE a.user_id = $1 
        AND a.is_active = true 
        AND a.deleted_at IS NULL
    ORDER BY a.created_at;
END;
$$ LANGUAGE plpgsql;

-- Verify table creation
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name IN ('accounts', 'account_types')
ORDER BY table_name, ordinal_position;
