-- Migration 015: Rename categories → expense_categories
-- Description: Standardize category table naming — expense_categories, income_categories, transfer_categories
-- Date: February 20, 2026

-- =====================================================================
-- Step 1: Rename the table
-- PostgreSQL tracks FK references by OID, so existing FKs in expenses
-- and budgets tables continue to work automatically after the rename.
-- =====================================================================
ALTER TABLE categories RENAME TO expense_categories;

-- =====================================================================
-- Step 2: Recreate all SQL functions that reference `categories` by name
-- =====================================================================

CREATE OR REPLACE FUNCTION update_category_usage(p_category_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE expense_categories
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
        c.parent_category_id AS parent_id,
        0 AS level,
        c.name::TEXT AS full_path
    FROM expense_categories c
    WHERE c.parent_category_id IS NULL
        AND c.is_active = true
        AND c.deleted_at IS NULL
        AND (
            (c.user_id IS NULL AND c.is_system = true)
            OR (p_user_id IS NOT NULL AND c.user_id = p_user_id)
        )

    UNION ALL

    -- Recursive case: child categories
    SELECT
        c.id,
        c.name::VARCHAR,
        c.category_type::VARCHAR,
        c.icon::VARCHAR,
        c.color::VARCHAR,
        c.parent_category_id AS parent_id,
        ct.level + 1,
        (ct.full_path || ' > ' || c.name)::TEXT
    FROM expense_categories c
    JOIN category_tree ct ON c.parent_category_id = ct.id
    WHERE c.is_active = true
        AND c.deleted_at IS NULL
        AND (
            (c.user_id IS NULL AND c.is_system = true)
            OR (p_user_id IS NOT NULL AND c.user_id = p_user_id)
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
    FROM expense_categories c
    WHERE (
        (c.user_id IS NULL AND c.is_system = true)
        OR (c.user_id = p_user_id)
    )
        AND c.category_type = p_category_type
        AND c.is_active = true
        AND c.deleted_at IS NULL
    ORDER BY c.usage_count DESC, c.last_used_at DESC NULLS LAST
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- Verify
-- =====================================================================
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('expense_categories', 'income_categories', 'transfer_categories')
ORDER BY table_name;
