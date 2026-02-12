-- ================================================================================================
-- Migration 013: Fix accounts UPDATE RLS policy
-- Description: Add WITH CHECK clause to accounts UPDATE policy to allow soft delete
-- Date: February 12, 2026
-- ================================================================================================

-- Drop existing UPDATE policy
DROP POLICY IF EXISTS "Users can update their own accounts" ON accounts;

-- Recreate UPDATE policy with both USING and WITH CHECK
CREATE POLICY "Users can update their own accounts" 
    ON accounts FOR UPDATE 
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Verify the policy
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'accounts' 
  AND policyname = 'Users can update their own accounts';
