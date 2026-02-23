-- ================================================================================================
-- Supabase Seed Data: FundvanceAI Financial Management System
-- Description: Complete seeder data for default categories, account types, and tax presets
-- Version: 1.0
-- Created: February 12, 2026
-- ================================================================================================

-- ================================================================================================
-- SECTION 1: DEFAULT CATEGORIES
-- Enhanced default categories with icons, colors, and hierarchical structure
-- ================================================================================================

-- Main Categories (System-wide defaults)
INSERT INTO expense_categories (
    name, category_type, description, icon, color, is_active, is_system, 
    sort_order, user_id, usage_count, created_at, updated_at, is_default
) VALUES
    -- EXPENSE CATEGORIES (System)
    ('Food & Dining', 'expense', 'Food, restaurants, groceries, and dining expenses', 'restaurant', '#FF6B6B', true, true, 1, NULL, 0, NOW(), NOW(), true),
    ('Transportation', 'expense', 'Car, gas, public transport, and travel expenses', 'directions_car', '#4ECDC4', true, true, 2, NULL, 0, NOW(), NOW(), true),
    ('Bills & Utilities', 'expense', 'Electricity, water, internet, and utility bills', 'receipt', '#45B7D1', true, true, 3, NULL, 0, NOW(), NOW(), true),
    ('Shopping', 'expense', 'Clothing, electronics, and general shopping', 'shopping_cart', '#96CEB4', true, true, 4, NULL, 0, NOW(), NOW(), true),
    ('Entertainment', 'expense', 'Movies, games, hobbies, and leisure activities', 'movie', '#FFEAA7', true, true, 5, NULL, 0, NOW(), NOW(), true),
    ('Healthcare', 'expense', 'Medical expenses, doctor visits, and medications', 'local_hospital', '#DDA15E', true, true, 6, NULL, 0, NOW(), NOW(), true),
    ('Housing & Rent', 'expense', 'Rent, mortgage, and housing-related expenses', 'home', '#607D8B', true, true, 7, NULL, 0, NOW(), NOW(), true),
    ('Education', 'expense', 'Tuition, books, courses, and educational expenses', 'school', '#3F51B5', true, true, 8, NULL, 0, NOW(), NOW(), true),
    ('Personal Care', 'expense', 'Haircuts, cosmetics, and personal grooming', 'face', '#FFC107', true, true, 9, NULL, 0, NOW(), NOW(), true),
    ('Others', 'expense', 'Miscellaneous expenses not covered elsewhere', 'more_horiz', '#95A5A6', true, true, 10, NULL, 0, NOW(), NOW(), true),

    -- INCOME CATEGORIES (System) 
    ('Salary & Wages', 'income', 'Primary employment income and wages', 'work', '#4CAF50', true, true, 11, NULL, 0, NOW(), NOW(), true),
    ('Business Income', 'income', 'Income from business operations and sales', 'business', '#FF9800', true, true, 12, NULL, 0, NOW(), NOW(), true),
    ('Freelance Work', 'income', 'Freelance projects and consulting income', 'person_add', '#2196F3', true, true, 13, NULL, 0, NOW(), NOW(), true),
    ('Investment Returns', 'income', 'Dividends, interest, and capital gains', 'trending_up', '#9C27B0', true, true, 14, NULL, 0, NOW(), NOW(), true),
    ('Other Income', 'income', 'Miscellaneous income not covered elsewhere', 'attach_money', '#757575', true, true, 15, NULL, 0, NOW(), NOW(), true),

    -- DUAL-PURPOSE CATEGORIES
    ('Banking & Finance', 'both', 'Bank fees, interest earned, and financial services', 'account_balance_wallet', '#1976D2', true, true, 16, NULL, 0, NOW(), NOW(), true);

-- Subcategories for Food & Dining
INSERT INTO expense_categories (
    name, category_type, description, icon, color, is_active, is_system,
    sort_order, user_id, usage_count, parent_category_id, created_at, updated_at, is_default
) VALUES
    ('Groceries', 'expense', 'Grocery shopping and food supplies', 'shopping_cart', '#FF6B6B', true, true, 1, NULL, 0, 
     (SELECT id FROM expense_categories WHERE name = 'Food & Dining' AND user_id IS NULL LIMIT 1),
     NOW(), NOW(), true),
    ('Dining Out', 'expense', 'Restaurant meals and dining experiences', 'restaurant', '#FF6B6B', true, true, 2, NULL, 0,
     (SELECT id FROM expense_categories WHERE name = 'Food & Dining' AND user_id IS NULL LIMIT 1),
     NOW(), NOW(), true),
    ('Coffee Shops', 'expense', 'Coffee, cafes, and beverage purchases', 'local_cafe', '#FF6B6B', true, true, 3, NULL, 0,
     (SELECT id FROM expense_categories WHERE name = 'Food & Dining' AND user_id IS NULL LIMIT 1),
     NOW(), NOW(), true),
    ('Food Delivery', 'expense', 'Food delivery and takeout orders', 'delivery_dining', '#FF6B6B', true, true, 4, NULL, 0,
     (SELECT id FROM expense_categories WHERE name = 'Food & Dining' AND user_id IS NULL LIMIT 1),
     NOW(), NOW(), true);

-- ================================================================================================
-- SECTION 2: INCOME CATEGORIES
-- Separate income categories for the income system
-- ================================================================================================

INSERT INTO income_categories (name, description, icon, color, is_active, is_system)
VALUES 
    ('Salary', 'Regular employment income from primary job', 'work', '#4CAF50', true, true),
    ('Freelance', 'Income from freelance work and consulting', 'person_add', '#2196F3', true, true),
    ('Business Income', 'Income from business operations and sales', 'business', '#FF9800', true, true),
    ('Investment Returns', 'Dividends, interest, and capital gains', 'trending_up', '#9C27B0', true, true),
    ('Rental Income', 'Income from rental properties', 'home', '#795548', true, true),
    ('Royalties', 'Income from intellectual property and royalties', 'library_music', '#E91E63', true, true),
    ('Commission', 'Sales commissions and performance bonuses', 'star', '#00BCD4', true, true),
    ('Government Benefits', 'Social security, unemployment, and other benefits', 'account_balance', '#607D8B', true, true),
    ('Pension', 'Retirement income and pension payments', 'elderly', '#8BC34A', true, true),
    ('Gift/Inheritance', 'Money received as gifts or inheritance', 'card_giftcard', '#FFC107', true, true),
    ('Side Hustle', 'Income from part-time work or gig economy', 'directions_run', '#FF5722', true, true),
    ('Other Income', 'Miscellaneous income not covered by other categories', 'more_horiz', '#757575', true, true)
ON CONFLICT (name) DO NOTHING;

-- ================================================================================================
-- SECTION 3: ACCOUNT TYPES
-- Default account types for various financial institutions and wallets
-- ================================================================================================

INSERT INTO account_types (code, name, description, icon, color, category, is_active)
VALUES
    -- CASH (created first — appears at top of default accounts list)
    ('CASH',           'Cash',              'Physical cash and notes on hand',                      'payments',          '#4CAF50', 'cash',        true),

    -- E-WALLET
    ('PAYPAL',         'PayPal',            'PayPal digital wallet',                                'account_balance_wallet', '#003087', 'e_wallet', true),
    ('APPLE_PAY',      'Apple Pay',         'Apple Pay digital wallet',                             'phone_iphone',      '#1C1C1E', 'e_wallet',    true),

    -- ONLINE BANK
    ('ONLINE_BANK',    'Online Bank',       'Digital-only online bank account',                     'language',          '#3949AB', 'online_bank', true),

    -- BANK
    ('CHECKING',       'Checking Account',  'Basic checking account for everyday transactions',     'account_balance',   '#2196F3', 'bank',        true),
    ('SAVINGS',        'Savings Account',   'Interest-bearing savings account',                     'savings',           '#1976D2', 'bank',        true),

    -- CREDIT
    ('CREDIT_CARD',    'Credit Card',       'Revolving credit card account',                        'credit_card',       '#F44336', 'credit',      true),
    ('LINE_OF_CREDIT', 'Line of Credit',    'Flexible credit line for larger purchases',            'credit_score',      '#E91E63', 'credit',      true),

    -- INVESTMENT
    ('INVESTMENT',     'Investment Account','Stocks, bonds, ETFs, and securities portfolio',        'trending_up',       '#9C27B0', 'investment',  true),

    -- CRYPTO (no default account created; users add manually)
    ('CRYPTO_WALLET',  'Crypto Wallet',     'Cryptocurrency wallet and digital asset holdings',     'currency_bitcoin',  '#FF9800', 'crypto',      true)

ON CONFLICT (code) DO NOTHING;

-- ================================================================================================
-- SECTION 4: TRANSFER CATEGORIES  
-- Default categories for account transfers and money movements
-- ================================================================================================

INSERT INTO transfer_categories (name, description, icon, color, is_active, is_system)
VALUES 
    ('Account Transfer', 'Transfer between your own accounts', 'swap_horiz', '#2196F3', true, true),
    ('Bill Payment', 'Transfer to pay bills and utilities', 'receipt', '#FF9800', true, true),
    ('Investment', 'Transfer to investment accounts', 'trending_up', '#4CAF50', true, true),
    ('Savings Goal', 'Transfer to dedicated savings for specific goals', 'savings', '#9C27B0', true, true),
    ('Emergency Fund', 'Transfer to emergency fund savings', 'security', '#F44336', true, true),
    ('Debt Payment', 'Transfer for loan or debt payments', 'credit_card_off', '#795548', true, true),
    ('Family Support', 'Money sent to family members', 'family_restroom', '#E91E63', true, true),
    ('Business Transfer', 'Business-related money movements', 'business', '#FF5722', true, true),
    ('Currency Exchange', 'Exchange between different currencies', 'currency_exchange', '#00BCD4', true, true),
    ('Refund', 'Money returned or refunded', 'refresh', '#607D8B', true, true),
    ('Other Transfer', 'Other types of transfers not listed', 'more_horiz', '#757575', true, true)
ON CONFLICT (name) DO NOTHING;

-- ================================================================================================
-- SECTION 5: TAX PRESETS
-- Default tax configurations for Philippines, USA, and generic worldwide settings
-- ================================================================================================

INSERT INTO tax_presets (
    country_code, tax_name, description, tax_type, tax_percentage, tax_fixed_amount, 
    currency, category_suggestion, is_mandatory, calculation_formula, tax_authority, 
    minimum_income_threshold, maximum_tax_cap, effective_tax_year, is_active
)
VALUES 
    -- PHILIPPINES TAX PRESETS
    ('PHL', 'Withholding Tax', 'Standard withholding tax on employment income', 'percentage', 20.00, NULL, 'PHP', 'Salary', true, 'Progressive tax based on BIR tax table', 'Bureau of Internal Revenue (BIR)', 250000, NULL, 2024, true),
    ('PHL', 'Freelancer Tax', 'Tax for freelance and professional services', 'percentage', 12.00, NULL, 'PHP', 'Freelance', false, '12% of gross income or graduated rates', 'Bureau of Internal Revenue (BIR)', 0, NULL, 2024, true),
    ('PHL', 'Business Income Tax', 'Corporate income tax for business', 'percentage', 25.00, NULL, 'PHP', 'Business Income', false, '25% of net taxable income', 'Bureau of Internal Revenue (BIR)', 0, NULL, 2024, true),
    ('PHL', 'PEZA Tax', 'Special tax rate for PEZA registered entities', 'percentage', 5.00, NULL, 'PHP', 'Business Income', false, '5% of gross income earned', 'PEZA', 0, NULL, 2024, true),
    ('PHL', '8% Optional Standard Deduction', 'Optional flat tax for professionals', 'percentage', 8.00, NULL, 'PHP', 'Freelance', false, '8% of gross receipts', 'Bureau of Internal Revenue (BIR)', 0, 3000000, 2024, true),
    ('PHL', 'Annual Registration Fee', 'Fixed BIR registration fee', 'fixed', NULL, 500.00, 'PHP', 'Business Income', true, 'Fixed annual amount', 'Bureau of Internal Revenue (BIR)', 0, NULL, 2024, true),
    ('PHL', 'Community Tax Certificate', 'Cedula or community tax', 'fixed', NULL, 5.00, 'PHP', 'Other Income', false, 'Minimum community tax', 'Local Government Unit', 0, NULL, 2024, true),

    -- UNITED STATES TAX PRESETS
    ('USA', 'Federal Income Tax', 'Federal income tax withholding', 'percentage', 22.00, NULL, 'USD', 'Salary', true, 'Progressive tax based on IRS tax brackets', 'Internal Revenue Service (IRS)', 12950, NULL, 2024, true),
    ('USA', 'State Income Tax - California', 'California state income tax', 'percentage', 9.30, NULL, 'USD', 'Salary', true, 'Progressive state tax', 'California Franchise Tax Board', 0, NULL, 2024, true),
    ('USA', 'State Income Tax - Texas', 'Texas has no state income tax', 'percentage', 0.00, NULL, 'USD', 'Salary', false, 'No state income tax', 'Texas Comptroller', 0, NULL, 2024, true),
    ('USA', 'Social Security Tax', 'Social Security contribution', 'percentage', 6.20, NULL, 'USD', 'Salary', true, '6.2% up to wage base limit', 'Social Security Administration', 0, 160200, 2024, true),
    ('USA', 'Medicare Tax', 'Medicare contribution', 'percentage', 1.45, NULL, 'USD', 'Salary', true, '1.45% of all wages', 'Centers for Medicare & Medicaid', 0, NULL, 2024, true),
    ('USA', 'Additional Medicare Tax', 'Additional Medicare tax for high earners', 'percentage', 0.90, NULL, 'USD', 'Salary', false, 'Additional 0.9% over threshold', 'Centers for Medicare & Medicaid', 200000, NULL, 2024, true),
    ('USA', 'Self-Employment Tax', 'Tax for self-employed individuals', 'percentage', 15.30, NULL, 'USD', 'Business Income', false, 'Combined Social Security and Medicare', 'Internal Revenue Service (IRS)', 400, 160200, 2024, true),
    ('USA', 'Quarterly Estimated Tax', 'Estimated tax for self-employed', 'percentage', 25.00, NULL, 'USD', 'Business Income', false, 'Estimated quarterly payment', 'Internal Revenue Service (IRS)', 0, NULL, 2024, true),

    -- GENERIC WORLDWIDE TAX PRESETS
    ('WLD', 'Basic Income Tax', 'Standard income tax rate', 'percentage', 15.00, NULL, 'USD', 'Salary', false, 'Basic income tax calculation', 'Tax Authority', 0, NULL, 2024, true),
    ('WLD', 'Professional Services Tax', 'Tax on professional services', 'percentage', 10.00, NULL, 'USD', 'Freelance', false, 'Tax on professional income', 'Tax Authority', 0, NULL, 2024, true),
    ('WLD', 'Business Profit Tax', 'Tax on business profits', 'percentage', 20.00, NULL, 'USD', 'Business Income', false, 'Tax on business income', 'Tax Authority', 0, NULL, 2024, true)
ON CONFLICT (country_code, tax_name, effective_tax_year) DO NOTHING;

-- ================================================================================================
-- SECTION 4: TRANSFER CATEGORIES
-- Default categories for account transfers and money movements
-- ================================================================================================

-- ================================================================================================
-- VERIFICATION QUERIES
-- Verify that seeder data has been properly inserted
-- ================================================================================================

-- Count categories by type
SELECT 
    category_type,
    COUNT(*) as count,
    COUNT(CASE WHEN parent_category_id IS NULL THEN 1 END) as main_categories,
    COUNT(CASE WHEN parent_category_id IS NOT NULL THEN 1 END) as subcategories
FROM expense_categories 
WHERE user_id IS NULL 
GROUP BY category_type
ORDER BY category_type;

-- Count account types by category
SELECT 
    category,
    COUNT(*) as count
FROM account_types 
WHERE is_active = true
GROUP BY category
ORDER BY category;

-- Count tax presets by country
SELECT 
    country_code,
    COUNT(*) as count
FROM tax_presets 
WHERE is_active = true
GROUP BY country_code
ORDER BY country_code;

-- Count income categories
SELECT 
    COUNT(*) as total_income_categories
FROM income_categories 
WHERE is_active = true;

-- Count transfer categories
SELECT 
    COUNT(*) as total_transfer_categories
FROM transfer_categories 
WHERE is_active = true;

-- Summary report
SELECT 
    'Categories' as data_type, COUNT(*) as total_records
FROM expense_categories WHERE user_id IS NULL
UNION ALL
SELECT 
    'Income Categories' as data_type, COUNT(*) as total_records
FROM income_categories WHERE is_active = true
UNION ALL
SELECT 
    'Transfer Categories' as data_type, COUNT(*) as total_records
FROM transfer_categories WHERE is_active = true
UNION ALL
SELECT 
    'Account Types' as data_type, COUNT(*) as total_records
FROM account_types WHERE is_active = true
UNION ALL
SELECT 
    'Tax Presets' as data_type, COUNT(*) as total_records
FROM tax_presets WHERE is_active = true;