-- Migration 010: Enhance Categories Table
-- Description: Enhance existing categories table with income support and advanced features
-- Date: February 12, 2026

-- Add new columns to existing categories table
ALTER TABLE categories 
    ADD COLUMN IF NOT EXISTS category_type VARCHAR(20) DEFAULT 'expense' 
        CHECK (category_type IN ('expense', 'income', 'both')),
    ADD COLUMN IF NOT EXISTS description TEXT,
    ADD COLUMN IF NOT EXISTS icon VARCHAR(50) DEFAULT 'category',
    ADD COLUMN IF NOT EXISTS color VARCHAR(7) DEFAULT '#757575',
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true,
    ADD COLUMN IF NOT EXISTS is_system BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS parent_category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS usage_count INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS last_used_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS category_settings JSONB DEFAULT '{}'::JSONB,
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE NULL;

-- CREATE INDEXES FOR ENHANCED CATEGORIES
CREATE INDEX IF NOT EXISTS idx_categories_type ON categories(category_type);
CREATE INDEX IF NOT EXISTS idx_categories_user_id ON categories(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_parent ON categories(parent_category_id);
CREATE INDEX IF NOT EXISTS idx_categories_active ON categories(is_active);
CREATE INDEX IF NOT EXISTS idx_categories_system ON categories(is_system);
CREATE INDEX IF NOT EXISTS idx_categories_deleted_at ON categories(deleted_at);
CREATE INDEX IF NOT EXISTS idx_categories_sort_order ON categories(sort_order);
CREATE INDEX IF NOT EXISTS idx_categories_last_used ON categories(last_used_at);

-- Create updated_at trigger for categories
DROP TRIGGER IF EXISTS set_updated_at_categories ON categories;
CREATE TRIGGER set_updated_at_categories
    BEFORE UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ENABLE ROW LEVEL SECURITY (if not already enabled)
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to recreate them
DROP POLICY IF EXISTS "Users can view their own categories" ON categories;
DROP POLICY IF EXISTS "Users can insert their own categories" ON categories;
DROP POLICY IF EXISTS "Users can update their own categories" ON categories;
DROP POLICY IF EXISTS "Users can delete their own categories" ON categories;

-- Create comprehensive RLS policies for enhanced categories
CREATE POLICY "Users can view categories" 
    ON categories FOR SELECT 
    USING (
        -- System categories (visible to all)
        (user_id IS NULL AND is_system = true AND is_active = true AND deleted_at IS NULL)
        OR 
        -- User's own categories
        (auth.uid() = user_id AND deleted_at IS NULL)
    );

CREATE POLICY "Users can insert their own categories" 
    ON categories FOR INSERT 
    WITH CHECK (auth.uid() = user_id AND is_system = false);

CREATE POLICY "Users can update their own categories" 
    ON categories FOR UPDATE 
    USING (auth.uid() = user_id AND is_system = false);

CREATE POLICY "Users can delete their own categories" 
    ON categories FOR DELETE 
    USING (auth.uid() = user_id AND is_system = false);

-- CATEGORY MANAGEMENT FUNCTIONS
CREATE OR REPLACE FUNCTION update_category_usage(p_category_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE categories 
    SET usage_count = usage_count + 1,
        last_used_at = NOW()
    WHERE id = p_category_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_category_hierarchy(p_user_id UUID DEFAULT NULL)
RETURNS TABLE(
    id UUID,
    name VARCHAR,
    category_type VARCHAR,
    icon VARCHAR,
    color VARCHAR,
    parent_id UUID,
    level INTEGER,
    full_path TEXT
) AS $$
WITH RECURSIVE category_tree AS (
    -- Base case: root categories
    SELECT 
        c.id,
        c.name::VARCHAR,
        c.category_type::VARCHAR,
        c.icon::VARCHAR,
        c.color::VARCHAR,
        c.parent_category_id as parent_id,
        0 as level,
        c.name::TEXT as full_path
    FROM categories c
    WHERE (c.parent_category_id IS NULL)
        AND c.is_active = true 
        AND c.deleted_at IS NULL
        AND (
            (c.user_id IS NULL AND c.is_system = true) 
            OR 
            (p_user_id IS NOT NULL AND c.user_id = p_user_id)
        )
    
    UNION ALL
    
    -- Recursive case: child categories
    SELECT 
        c.id,
        c.name::VARCHAR,
        c.category_type::VARCHAR,
        c.icon::VARCHAR,
        c.color::VARCHAR,
        c.parent_category_id as parent_id,
        ct.level + 1,
        (ct.full_path || ' > ' || c.name)::TEXT
    FROM categories c
    JOIN category_tree ct ON c.parent_category_id = ct.id
    WHERE c.is_active = true 
        AND c.deleted_at IS NULL
        AND (
            (c.user_id IS NULL AND c.is_system = true) 
            OR 
            (p_user_id IS NOT NULL AND c.user_id = p_user_id)
        )
)
SELECT * FROM category_tree ORDER BY level, name;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_popular_categories(
    p_user_id UUID,
    p_category_type VARCHAR DEFAULT 'expense',
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE(
    id UUID,
    name VARCHAR,
    icon VARCHAR,
    color VARCHAR,
    usage_count INTEGER,
    last_used_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.name::VARCHAR,
        c.icon::VARCHAR,
        c.color::VARCHAR,
        c.usage_count,
        c.last_used_at
    FROM categories c
    WHERE (
            (c.user_id IS NULL AND c.is_system = true) 
            OR 
            (c.user_id = p_user_id)
        )
        AND c.category_type = p_category_type
        AND c.is_active = true 
        AND c.deleted_at IS NULL
    ORDER BY c.usage_count DESC, c.last_used_at DESC NULLS LAST
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Update existing system categories to have enhanced fields
UPDATE categories 
SET 
    category_type = 'expense',
    is_system = true,
    is_active = true,
    sort_order = CASE 
        WHEN name = 'Food' THEN 1
        WHEN name = 'Transport' THEN 2  
        WHEN name = 'Bills' THEN 3
        WHEN name = 'Shopping' THEN 4
        WHEN name = 'Entertainment' THEN 5
        WHEN name = 'Healthcare' THEN 6
        WHEN name = 'Others' THEN 7
        ELSE 10
    END,
    updated_at = NOW()
WHERE user_id IS NULL;

-- Verify enhanced categories structure
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'categories'
    AND column_name IN ('category_type', 'description', 'icon', 'color', 'is_active', 'is_system', 'sort_order', 'parent_category_id', 'user_id', 'usage_count', 'last_used_at', 'updated_at', 'category_settings', 'deleted_at')
ORDER BY ordinal_position;
