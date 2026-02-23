-- Track Stripe subscription status so the app can detect free trials
-- separately from fully-paid subscriptions.
-- Allowed values mirror Stripe subscription statuses:
--   trialing | active | past_due | canceled | unpaid | incomplete | paused

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS subscription_status  text;

COMMENT ON COLUMN profiles.subscription_status IS
  'Mirrors the Stripe subscription status. NULL = never subscribed.';
