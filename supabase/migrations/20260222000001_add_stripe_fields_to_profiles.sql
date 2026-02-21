-- Add Stripe billing fields to profiles for web/desktop premium subscriptions
-- RevenueCat handles iOS/Android; Stripe handles Web/Desktop

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS is_premium          boolean      NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS stripe_customer_id  text,
  ADD COLUMN IF NOT EXISTS premium_expires_at  timestamptz;

-- Index for webhook lookups by Stripe customer ID
CREATE INDEX IF NOT EXISTS profiles_stripe_customer_id_idx
  ON profiles (stripe_customer_id)
  WHERE stripe_customer_id IS NOT NULL;

-- Users can read and update their own premium status
-- (INSERT/UPDATE RLS already covered by existing profiles policy)
