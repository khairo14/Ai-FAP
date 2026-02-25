-- Add theme preference and favourite merchants to profiles so they sync
-- across devices (web ↔ mobile ↔ desktop).
--
-- theme_id     : matches AppThemes ids ('light', 'dark', 'midnight', …)
-- favourite_merchants : text array managed by ExpenseProvider

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS theme_id            text    NOT NULL DEFAULT 'light',
  ADD COLUMN IF NOT EXISTS favourite_merchants text[]  NOT NULL DEFAULT '{}';

COMMENT ON COLUMN profiles.theme_id IS
  'User-selected app theme. Synced across devices. Defaults to light.';

COMMENT ON COLUMN profiles.favourite_merchants IS
  'Pinned merchant names shown at the top of expense form suggestions.';
