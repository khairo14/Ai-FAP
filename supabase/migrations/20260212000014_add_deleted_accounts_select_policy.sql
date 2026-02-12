-- ================================================================================================
-- Migration 014: Add SELECT policy for deleted accounts
-- Description: Allow users to SELECT their own deleted accounts (needed for soft delete updates)
-- Date: February 12, 2026
-- ================================================================================================

-- Add policy to allow users to view their own deleted accounts
-- This is needed because UPDATE operations check SELECT permission after the update
-- Without this, setting deleted_at fails the SELECT policy check
CREATE POLICY "Users can view their own deleted accounts" 
    ON accounts FOR SELECT 
    USING (auth.uid() = user_id AND deleted_at IS NOT NULL);

-- Verify the policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'accounts' 
  AND policyname LIKE '%deleted%'
ORDER BY policyname;
