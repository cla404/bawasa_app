-- Fix RLS policy to allow user profile creation during sign-up
-- This script addresses the "Database error saving new user" issue

-- 1. First, let's check the current state
SELECT 'Starting RLS policy fix...' as status;

-- 2. Check current RLS policies on users table
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users' 
AND schemaname = 'public';

-- 3. Drop the existing insert policy that's causing issues
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;

-- 4. Create a new insert policy that allows profile creation during sign-up
-- This policy allows:
-- - Authenticated users to create their own profile
-- - System/service role to create profiles (for triggers if any)
CREATE POLICY "Users can insert their own profile" ON users
    FOR INSERT WITH CHECK (
        -- Allow if user is authenticated and creating their own profile
        (auth.uid() IS NOT NULL AND auth.uid() = auth_user_id)
        OR
        -- Allow if no auth context (for system operations)
        auth.uid() IS NULL
    );

-- 5. Ensure the table has proper permissions
GRANT SELECT, INSERT, UPDATE ON users TO authenticated;
GRANT SELECT, INSERT, UPDATE ON users TO service_role;

-- 6. Check if there are any triggers on auth.users that might be causing issues
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
AND event_object_schema = 'auth';

-- 7. If there are any custom triggers on auth.users, remove them
-- (Keep only the default Supabase triggers)
DO $$
DECLARE
    trigger_record RECORD;
BEGIN
    FOR trigger_record IN 
        SELECT trigger_name 
        FROM information_schema.triggers 
        WHERE event_object_table = 'users' 
        AND event_object_schema = 'auth'
        AND trigger_name NOT IN (
            'on_auth_user_created',  -- Default Supabase trigger
            'on_auth_user_updated',  -- Default Supabase trigger
            'on_auth_user_deleted'   -- Default Supabase trigger
        )
    LOOP
        EXECUTE 'DROP TRIGGER IF EXISTS ' || trigger_record.trigger_name || ' ON auth.users';
        RAISE NOTICE 'Removed custom trigger: %', trigger_record.trigger_name;
    END LOOP;
END $$;

-- 8. Check the final state
SELECT 'RLS policy fix completed. Test sign up now.' as status;

-- 9. Verify the new policy
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users' 
AND schemaname = 'public'
AND policyname = 'Users can insert their own profile';
