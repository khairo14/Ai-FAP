-- Seeder 001: Default Categories
-- Description: Insert 11 default categories (7 main + 4 food subcategories)
-- Date: Phase 1 Setup
-- Run this AFTER all table migrations are complete

-- Insert 7 main default categories
INSERT INTO categories (user_id, name, icon, color, is_default) VALUES
  (NULL, 'Food', '🍔', '#FF6B6B', true),
  (NULL, 'Transport', '🚗', '#4ECDC4', true),
  (NULL, 'Bills', '📄', '#45B7D1', true),
  (NULL, 'Shopping', '🛍️', '#96CEB4', true),
  (NULL, 'Entertainment', '🎬', '#FFEAA7', true),
  (NULL, 'Healthcare', '⚕️', '#DDA15E', true),
  (NULL, 'Others', '📌', '#95A5A6', true);

-- Insert 4 food subcategories
INSERT INTO categories (user_id, name, icon, color, is_default, parent_id) VALUES
  (NULL, 'Groceries', '🛒', '#FF6B6B', true, (SELECT id FROM categories WHERE name = 'Food' AND user_id IS NULL LIMIT 1)),
  (NULL, 'Dining Out', '🍽️', '#FF6B6B', true, (SELECT id FROM categories WHERE name = 'Food' AND user_id IS NULL LIMIT 1)),
  (NULL, 'Coffee Shops', '☕', '#FF6B6B', true, (SELECT id FROM categories WHERE name = 'Food' AND user_id IS NULL LIMIT 1)),
  (NULL, 'Food Delivery', '🍕', '#FF6B6B', true, (SELECT id FROM categories WHERE name = 'Food' AND user_id IS NULL LIMIT 1));

-- Verify seeded data
SELECT id, name, icon, is_default, parent_id 
FROM categories 
WHERE user_id IS NULL 
ORDER BY created_at;
