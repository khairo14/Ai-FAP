-- Migration 009: Create Tax System
-- Description: Complete tax management system with presets and user preferences
-- Date: February 12, 2026

-- Create tax presets table
CREATE TABLE tax_presets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    country_code VARCHAR(3) NOT NULL DEFAULT 'PHL',
    tax_name VARCHAR(255) NOT NULL,
    description TEXT,
    tax_type VARCHAR(20) NOT NULL CHECK (tax_type IN ('percentage', 'fixed', 'hybrid')),
    tax_percentage DECIMAL(5,2),
    tax_fixed_amount DECIMAL(15,2),
    currency VARCHAR(3) NOT NULL,
    
    -- Preset metadata
    category_suggestion VARCHAR(100),
    is_mandatory BOOLEAN DEFAULT false,
    calculation_formula TEXT,
    tax_authority VARCHAR(255),
    
    -- Applicability
    minimum_income_threshold DECIMAL(15,2),
    maximum_tax_cap DECIMAL(15,2),
    effective_tax_year INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(country_code, tax_name, effective_tax_year)
);

-- Create default tax rates table
CREATE TABLE default_tax_rates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    income_category_id UUID REFERENCES income_categories(id) ON DELETE CASCADE,
    
    -- Tax calculation settings
    tax_type VARCHAR(20) NOT NULL CHECK (tax_type IN ('percentage', 'fixed', 'hybrid')),
    tax_percentage DECIMAL(5,2) CHECK (tax_percentage >= 0 AND tax_percentage <= 100),
    tax_fixed_amount DECIMAL(15,2) CHECK (tax_fixed_amount >= 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    
    -- Tax details
    tax_name VARCHAR(255),
    description TEXT,
    is_mandatory BOOLEAN DEFAULT false,
    calculation_formula TEXT,
    
    -- Settings
    is_active BOOLEAN DEFAULT true,
    is_default_for_category BOOLEAN DEFAULT false,
    apply_automatically BOOLEAN DEFAULT true,
    
    -- Threshold settings
    minimum_income_threshold DECIMAL(15,2),
    maximum_tax_cap DECIMAL(15,2),
    
    -- Metadata
    tax_authority VARCHAR(255),
    effective_from DATE DEFAULT CURRENT_DATE,
    effective_to DATE,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE NULL
);

-- CREATE INDEXES
CREATE INDEX idx_default_tax_rates_user_id ON default_tax_rates(user_id);
CREATE INDEX idx_default_tax_rates_category ON default_tax_rates(income_category_id);
CREATE INDEX idx_default_tax_rates_active ON default_tax_rates(is_active);
CREATE INDEX idx_default_tax_rates_deleted_at ON default_tax_rates(deleted_at);
CREATE INDEX idx_tax_presets_country ON tax_presets(country_code, is_active);
CREATE INDEX idx_tax_presets_year ON tax_presets(effective_tax_year, is_active);

-- CREATE TRIGGERS
CREATE TRIGGER set_updated_at_tax_presets
    BEFORE UPDATE ON tax_presets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_updated_at_default_tax_rates
    BEFORE UPDATE ON default_tax_rates
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ENABLE ROW LEVEL SECURITY
ALTER TABLE tax_presets ENABLE ROW LEVEL SECURITY;
ALTER TABLE default_tax_rates ENABLE ROW LEVEL SECURITY;

-- RLS POLICIES FOR TAX PRESETS
CREATE POLICY "Users can view active tax presets" 
    ON tax_presets FOR SELECT 
    USING (is_active = true);

-- RLS POLICIES FOR DEFAULT TAX RATES
CREATE POLICY "Users can view their own tax rates" 
    ON default_tax_rates FOR SELECT 
    USING (auth.uid() = user_id AND deleted_at IS NULL);

CREATE POLICY "Users can insert their own tax rates" 
    ON default_tax_rates FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own tax rates" 
    ON default_tax_rates FOR UPDATE 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own tax rates" 
    ON default_tax_rates FOR DELETE 
    USING (auth.uid() = user_id);

-- TAX MANAGEMENT FUNCTIONS
CREATE OR REPLACE FUNCTION get_default_tax_for_category(
    p_user_id UUID,
    p_category_id UUID
)
RETURNS TABLE(
    tax_type VARCHAR,
    tax_percentage DECIMAL,
    tax_fixed_amount DECIMAL,
    tax_name VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dtr.tax_type::VARCHAR,
        dtr.tax_percentage,
        dtr.tax_fixed_amount,
        dtr.tax_name::VARCHAR
    FROM default_tax_rates dtr
    WHERE dtr.user_id = p_user_id 
        AND dtr.income_category_id = p_category_id
        AND dtr.is_active = true 
        AND dtr.deleted_at IS NULL
        AND dtr.is_default_for_category = true
    ORDER BY dtr.created_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION apply_tax_preset_to_user(
    p_user_id UUID,
    p_preset_id UUID,
    p_category_id UUID DEFAULT NULL,
    p_set_as_default BOOLEAN DEFAULT false
)
RETURNS UUID AS $$
DECLARE
    preset_record tax_presets%ROWTYPE;
    new_tax_rate_id UUID;
BEGIN
    -- Get preset details
    SELECT * INTO preset_record
    FROM tax_presets
    WHERE id = p_preset_id AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tax preset not found or inactive';
    END IF;
    
    -- Create user tax rate from preset
    INSERT INTO default_tax_rates (
        user_id, income_category_id, tax_type, tax_percentage, tax_fixed_amount,
        currency, tax_name, description, is_mandatory, calculation_formula,
        is_default_for_category, apply_automatically, minimum_income_threshold,
        maximum_tax_cap, tax_authority
    ) VALUES (
        p_user_id, p_category_id, preset_record.tax_type, 
        preset_record.tax_percentage, preset_record.tax_fixed_amount,
        preset_record.currency, preset_record.tax_name, preset_record.description,
        preset_record.is_mandatory, preset_record.calculation_formula,
        p_set_as_default, true, preset_record.minimum_income_threshold,
        preset_record.maximum_tax_cap, preset_record.tax_authority
    ) RETURNING id INTO new_tax_rate_id;
    
    RETURN new_tax_rate_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calculate_tax_with_defaults(
    p_user_id UUID,
    p_category_id UUID,
    p_income_amount DECIMAL
)
RETURNS TABLE(
    calculated_tax DECIMAL,
    net_amount DECIMAL,
    tax_breakdown JSONB
) AS $$
DECLARE
    default_tax_record RECORD;
    tax_amount DECIMAL := 0;
    breakdown JSONB := '[]'::JSONB;
BEGIN
    -- Get default tax settings for category
    FOR default_tax_record IN 
        SELECT * FROM default_tax_rates 
        WHERE user_id = p_user_id 
            AND (income_category_id = p_category_id OR income_category_id IS NULL)
            AND is_active = true 
            AND apply_automatically = true 
            AND deleted_at IS NULL
        ORDER BY is_default_for_category DESC, created_at DESC
    LOOP
        -- Check thresholds
        IF (default_tax_record.minimum_income_threshold IS NULL OR 
            p_income_amount >= default_tax_record.minimum_income_threshold) THEN
            
            -- Calculate tax for this rule
            DECLARE
                rule_tax DECIMAL := 0;
            BEGIN
                rule_tax := calculate_income_tax(
                    p_income_amount,
                    default_tax_record.tax_type,
                    default_tax_record.tax_percentage,
                    default_tax_record.tax_fixed_amount
                );
                
                -- Apply maximum cap if specified
                IF default_tax_record.maximum_tax_cap IS NOT NULL THEN
                    rule_tax := LEAST(rule_tax, default_tax_record.maximum_tax_cap);
                END IF;
                
                tax_amount := tax_amount + rule_tax;
                
                -- Add to breakdown
                breakdown := breakdown || jsonb_build_object(
                    'tax_name', default_tax_record.tax_name,
                    'tax_type', default_tax_record.tax_type,
                    'calculated_amount', rule_tax,
                    'percentage', default_tax_record.tax_percentage,
                    'fixed_amount', default_tax_record.tax_fixed_amount
                );
            END;
        END IF;
    END LOOP;
    
    RETURN QUERY SELECT tax_amount, p_income_amount - tax_amount, breakdown;
END;
$$ LANGUAGE plpgsql;

-- Verify table creation
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name IN ('tax_presets', 'default_tax_rates')
ORDER BY table_name, ordinal_position;
