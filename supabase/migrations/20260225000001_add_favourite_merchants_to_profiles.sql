-- ─────────────────────────────────────────────────────────────────────────────
-- Add favourite_merchants column to profiles table.
-- Stores a list of merchant name strings the user has pinned as favourites.
-- Previously stored in SharedPreferences (device-local); now synced to Supabase
-- so favourites persist across devices and survive app reinstall.
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS favourite_merchants TEXT[] NOT NULL DEFAULT '{}';

COMMENT ON COLUMN profiles.favourite_merchants IS
  'User-pinned merchant names shown at the top of expense form suggestions.';
