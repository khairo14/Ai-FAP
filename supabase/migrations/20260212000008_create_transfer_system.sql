-- Migration 008: Create Transfer System
-- Description: Complete transfer system with multi-currency support and exchange rates
-- Date: February 12, 2026

-- Create transfer categories table
CREATE TABLE transfer_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    icon VARCHAR(50) DEFAULT 'swap_horiz',
    color VARCHAR(7) DEFAULT '#2196F3',
    is_active BOOLEAN DEFAULT true,
    is_system BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create transfers table
CREATE TABLE transfers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES transfer_categories(id) ON DELETE SET NULL,
    
    -- Transfer accounts
    from_account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
    to_account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
    
    -- Transfer amounts and currencies
    from_amount DECIMAL(15,2) NOT NULL CHECK (from_amount > 0),
    from_currency VARCHAR(3) NOT NULL,
    to_amount DECIMAL(15,2) NOT NULL CHECK (to_amount > 0),
    to_currency VARCHAR(3) NOT NULL,
    
    -- Exchange rate information
    exchange_rate DECIMAL(15,8),
    exchange_rate_source VARCHAR(50),
    is_manual_rate BOOLEAN DEFAULT false,
    
    -- Fee information
    transfer_fee DECIMAL(15,2) DEFAULT 0,
    fee_currency VARCHAR(3),
    fee_charged_to VARCHAR(20) DEFAULT 'from' CHECK (fee_charged_to IN ('from', 'to', 'separate')),
    fee_description TEXT,
    
    -- Transfer details
    description TEXT,
    transfer_date DATE NOT NULL DEFAULT CURRENT_DATE,
    reference_number VARCHAR(100),
    
    -- Status tracking
    status VARCHAR(20) DEFAULT 'completed' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
    processed_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    transfer_method VARCHAR(50),
    notes TEXT,
    attachments JSONB,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE NULL,
    
    -- Constraints
    CHECK (from_account_id != to_account_id)
);

-- Create exchange rates history table
CREATE TABLE exchange_rates_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    from_currency VARCHAR(3) NOT NULL,
    to_currency VARCHAR(3) NOT NULL,
    rate DECIMAL(15,8) NOT NULL,
    source VARCHAR(50) NOT NULL,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(from_currency, to_currency, effective_date, source)
);

-- CREATE INDEXES
CREATE INDEX idx_transfers_user_id ON transfers(user_id);
CREATE INDEX idx_transfers_from_account ON transfers(from_account_id);
CREATE INDEX idx_transfers_to_account ON transfers(to_account_id);
CREATE INDEX idx_transfers_date ON transfers(transfer_date);
CREATE INDEX idx_transfers_status ON transfers(status);
CREATE INDEX idx_transfers_deleted_at ON transfers(deleted_at);
CREATE INDEX idx_exchange_rates_currencies ON exchange_rates_history(from_currency, to_currency, effective_date);

-- CREATE TRIGGERS
CREATE TRIGGER set_updated_at_transfer_categories
    BEFORE UPDATE ON transfer_categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_updated_at_transfers
    BEFORE UPDATE ON transfers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ENABLE ROW LEVEL SECURITY
ALTER TABLE transfer_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE transfers ENABLE ROW LEVEL SECURITY;
ALTER TABLE exchange_rates_history ENABLE ROW LEVEL SECURITY;

-- RLS POLICIES FOR TRANSFER CATEGORIES
CREATE POLICY "Users can view active transfer categories" 
    ON transfer_categories FOR SELECT 
    USING (is_active = true);

-- RLS POLICIES FOR TRANSFERS
CREATE POLICY "Users can view their own transfers" 
    ON transfers FOR SELECT 
    USING (auth.uid() = user_id AND deleted_at IS NULL);

CREATE POLICY "Users can insert their own transfers" 
    ON transfers FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own transfers" 
    ON transfers FOR UPDATE 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own transfers" 
    ON transfers FOR DELETE 
    USING (auth.uid() = user_id);

-- RLS POLICIES FOR EXCHANGE RATES
CREATE POLICY "Users can view exchange rates" 
    ON exchange_rates_history FOR SELECT 
    USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert exchange rates" 
    ON exchange_rates_history FOR INSERT 
    WITH CHECK (auth.role() = 'authenticated');

-- TRANSFER MANAGEMENT FUNCTIONS
CREATE OR REPLACE FUNCTION get_latest_exchange_rate(
    from_curr VARCHAR,
    to_curr VARCHAR
)
RETURNS DECIMAL AS $$
DECLARE
    latest_rate DECIMAL;
BEGIN
    SELECT rate INTO latest_rate
    FROM exchange_rates_history
    WHERE from_currency = from_curr 
        AND to_currency = to_curr
    ORDER BY effective_date DESC, created_at DESC
    LIMIT 1;
    
    RETURN COALESCE(latest_rate, 1.0);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION process_transfer(
    p_user_id UUID,
    p_from_account UUID,
    p_to_account UUID,
    p_amount DECIMAL,
    p_fee DECIMAL DEFAULT 0,
    p_from_currency VARCHAR DEFAULT 'USD',
    p_to_currency VARCHAR DEFAULT 'USD',
    p_exchange_rate DECIMAL DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_category_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    transfer_id UUID;
    calculated_to_amount DECIMAL;
    final_exchange_rate DECIMAL;
BEGIN
    -- Calculate exchange rate if not provided
    IF p_exchange_rate IS NULL THEN
        final_exchange_rate := get_latest_exchange_rate(p_from_currency, p_to_currency);
    ELSE
        final_exchange_rate := p_exchange_rate;
    END IF;
    
    -- Calculate to amount
    calculated_to_amount := p_amount * final_exchange_rate;
    
    -- Create transfer record
    INSERT INTO transfers (
        user_id, from_account_id, to_account_id, category_id,
        from_amount, from_currency, to_amount, to_currency,
        exchange_rate, transfer_fee, description, status
    ) VALUES (
        p_user_id, p_from_account, p_to_account, p_category_id,
        p_amount, p_from_currency, calculated_to_amount, p_to_currency,
        final_exchange_rate, p_fee, p_description, 'completed'
    ) RETURNING id INTO transfer_id;
    
    -- Update account balances
    PERFORM update_account_balance(p_from_account, p_amount + p_fee, 'subtract');
    PERFORM update_account_balance(p_to_account, calculated_to_amount, 'add');
    
    RETURN transfer_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_transfer_summary(
    p_user_id UUID,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE(
    total_transfers BIGINT,
    total_amount DECIMAL,
    currency VARCHAR,
    avg_amount DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT as total_transfers,
        SUM(t.from_amount) as total_amount,
        t.from_currency::VARCHAR as currency,
        AVG(t.from_amount) as avg_amount
    FROM transfers t
    WHERE t.user_id = p_user_id 
        AND t.deleted_at IS NULL
        AND t.status = 'completed'
        AND (p_start_date IS NULL OR t.transfer_date >= p_start_date)
        AND (p_end_date IS NULL OR t.transfer_date <= p_end_date)
    GROUP BY t.from_currency;
END;
$$ LANGUAGE plpgsql;

-- Verify table creation
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name IN ('transfers', 'transfer_categories', 'exchange_rates_history')
ORDER BY table_name, ordinal_position;
