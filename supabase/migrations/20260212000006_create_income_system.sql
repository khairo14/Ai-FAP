-- Migration 006: Create Income System
-- Description: Complete income tracking system with categories and tax calculation
-- Date: February 12, 2026

-- Create income categories table
CREATE TABLE income_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    icon VARCHAR(50) DEFAULT 'money',
    color VARCHAR(7) DEFAULT '#4CAF50',
    is_active BOOLEAN DEFAULT true,
    is_system BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE NULL
);

-- Create income table
CREATE TABLE income (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES income_categories(id) ON DELETE RESTRICT,
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    description TEXT,
    income_date DATE NOT NULL DEFAULT CURRENT_DATE,
    
    -- Tax calculation fields
    tax_type VARCHAR(20) CHECK (tax_type IN ('percentage', 'fixed', 'hybrid')),
    tax_percentage DECIMAL(5,2) CHECK (tax_percentage >= 0 AND tax_percentage <= 100),
    tax_fixed_amount DECIMAL(15,2) CHECK (tax_fixed_amount >= 0),
    tax_calculated DECIMAL(15,2) DEFAULT 0,
    net_amount DECIMAL(15,2) NOT NULL,
    
    -- Metadata
    source_details JSONB,
    is_recurring BOOLEAN DEFAULT false,
    recurrence_pattern VARCHAR(20) CHECK (recurrence_pattern IN ('daily', 'weekly', 'monthly', 'yearly')),
    next_occurrence DATE,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE NULL
);

-- CREATE INDEXES
CREATE INDEX idx_income_user_id ON income(user_id);
CREATE INDEX idx_income_category_id ON income(category_id);
CREATE INDEX idx_income_date ON income(income_date);
CREATE INDEX idx_income_deleted_at ON income(deleted_at);
CREATE INDEX idx_income_categories_deleted_at ON income_categories(deleted_at);

-- CREATE TRIGGERS
CREATE TRIGGER set_updated_at_income_categories
    BEFORE UPDATE ON income_categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_updated_at_income
    BEFORE UPDATE ON income
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ENABLE ROW LEVEL SECURITY
ALTER TABLE income_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE income ENABLE ROW LEVEL SECURITY;

-- RLS POLICIES FOR INCOME CATEGORIES
CREATE POLICY "Users can view active income categories" 
    ON income_categories FOR SELECT 
    USING (is_active = true AND deleted_at IS NULL);

-- RLS POLICIES FOR INCOME
CREATE POLICY "Users can view their own income" 
    ON income FOR SELECT 
    USING (auth.uid() = user_id AND deleted_at IS NULL);

CREATE POLICY "Users can insert their own income" 
    ON income FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own income" 
    ON income FOR UPDATE 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own income" 
    ON income FOR DELETE 
    USING (auth.uid() = user_id);

-- TAX CALCULATION FUNCTIONS
CREATE OR REPLACE FUNCTION calculate_income_tax(
    gross_amount DECIMAL,
    tax_type_param VARCHAR,
    tax_percentage_param DECIMAL DEFAULT NULL,
    tax_fixed_param DECIMAL DEFAULT NULL
)
RETURNS DECIMAL AS $$
DECLARE
    calculated_tax DECIMAL := 0;
BEGIN
    CASE tax_type_param
        WHEN 'percentage' THEN
            IF tax_percentage_param IS NOT NULL THEN
                calculated_tax := gross_amount * (tax_percentage_param / 100);
            END IF;
        WHEN 'fixed' THEN
            IF tax_fixed_param IS NOT NULL THEN
                calculated_tax := tax_fixed_param;
            END IF;
        WHEN 'hybrid' THEN
            IF tax_percentage_param IS NOT NULL AND tax_fixed_param IS NOT NULL THEN
                calculated_tax := (gross_amount * (tax_percentage_param / 100)) + tax_fixed_param;
            END IF;
        ELSE
            calculated_tax := 0;
    END CASE;
    
    RETURN COALESCE(calculated_tax, 0);
END;
$$ LANGUAGE plpgsql;

-- Auto-calculate net income trigger
CREATE OR REPLACE FUNCTION calculate_net_income()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate tax if tax type is provided
    IF NEW.tax_type IS NOT NULL THEN
        NEW.tax_calculated := calculate_income_tax(
            NEW.amount,
            NEW.tax_type,
            NEW.tax_percentage,
            NEW.tax_fixed_amount
        );
    ELSE
        NEW.tax_calculated := 0;
    END IF;
    
    -- Calculate net amount
    NEW.net_amount := NEW.amount - COALESCE(NEW.tax_calculated, 0);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_income_net_amount
    BEFORE INSERT OR UPDATE ON income
    FOR EACH ROW
    EXECUTE FUNCTION calculate_net_income();

-- Verify table creation
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name IN ('income', 'income_categories')
ORDER BY table_name, ordinal_position;
