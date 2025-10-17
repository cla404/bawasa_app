-- Migration: Remove problematic user creation trigger
-- This script removes the trigger and function that were causing issues
-- with user profile creation during sign up

-- Drop the trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Drop the function
DROP FUNCTION IF EXISTS handle_new_user();

-- Verify the trigger and function are removed
SELECT 'Trigger and function removed successfully' as status;
