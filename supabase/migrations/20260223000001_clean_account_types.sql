-- Migration: Clean up account_types to the canonical 7-category set
-- Removes Google Pay, GCash; renames Cryptocurrency → Crypto Wallet;
-- fixes icons for Online Bank, Apple Pay, Cash;
-- rewrites create_default_accounts to create exactly the right defaults in order.

-- ─────────────────────────────────────────────────────────────────────
-- 1. Re-assign accounts that use types we are removing
--    (prevents FK violation when deleting those types)
-- ─────────────────────────────────────────────────────────────────────
UPDATE accounts
SET account_type_id = (
    SELECT id FROM account_types WHERE code = 'PAYPAL' LIMIT 1
)
WHERE account_type_id IN (
    SELECT id FROM account_types WHERE code IN ('GOOGLE_PAY', 'GCASH')
);

-- ─────────────────────────────────────────────────────────────────────
-- 2. Remove unwanted types
-- ─────────────────────────────────────────────────────────────────────
DELETE FROM account_types WHERE code IN ('GOOGLE_PAY', 'GCASH');

-- ─────────────────────────────────────────────────────────────────────
-- 3. Fix icons / rename remaining types
-- ─────────────────────────────────────────────────────────────────────

-- Cash: brighter green, correct payments icon
UPDATE account_types
SET icon = 'payments', color = '#4CAF50'
WHERE code = 'CASH';

-- Online Bank: globe icon matching Flutter Icons.language
UPDATE account_types
SET icon = 'language', color = '#3949AB'
WHERE code = 'ONLINE_BANK';

-- Apple Pay: phone icon
UPDATE account_types
SET icon = 'phone_iphone', color = '#1C1C1E'
WHERE code = 'APPLE_PAY';

-- Crypto: rename from generic Cryptocurrency to Crypto Wallet
UPDATE account_types
SET code = 'CRYPTO_WALLET', name = 'Crypto Wallet',
    description = 'Cryptocurrency wallet and digital asset holdings',
    icon = 'currency_bitcoin', color = '#FF9800'
WHERE code = 'CRYPTOCURRENCY';

-- ─────────────────────────────────────────────────────────────────────
-- 4. Rewrite create_default_accounts
--    Creates exactly the right accounts in the right order (Cash first)
-- ─────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION create_default_accounts()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_currency TEXT;

    -- The ordered list of default account types to create
    v_defaults TEXT[] := ARRAY[
        'CASH',           -- cash           (first)
        'PAYPAL',         -- e_wallet
        'APPLE_PAY',      -- e_wallet
        'ONLINE_BANK',    -- online_bank
        'CHECKING',       -- bank
        'SAVINGS',        -- bank
        'CREDIT_CARD',    -- credit
        'LINE_OF_CREDIT', -- credit
        'INVESTMENT'      -- investment
        -- No crypto default: users add it manually
    ];

    v_code   TEXT;
    v_type   RECORD;
BEGIN
    v_currency := COALESCE(NEW.currency, 'USD');

    FOREACH v_code IN ARRAY v_defaults LOOP
        SELECT id, name, description
        INTO v_type
        FROM account_types
        WHERE code = v_code AND is_active = true
        LIMIT 1;

        IF v_type.id IS NOT NULL THEN
            INSERT INTO accounts (
                id, user_id, account_type_id, name, currency,
                initial_balance, current_balance, available_balance,
                description, is_active, include_in_total,
                created_at, updated_at
            ) VALUES (
                gen_random_uuid(),
                NEW.id,
                v_type.id,
                v_type.name,
                v_currency,
                0.00, 0.00, 0.00,
                v_type.description,
                true, true,
                NOW(), NOW()
            );
        END IF;
    END LOOP;

    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION create_default_accounts() IS
'Creates 9 default accounts for new users in a fixed order (Cash first).
Crypto wallet is intentionally excluded — users add it if needed.';
