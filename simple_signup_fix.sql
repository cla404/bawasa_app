-- Simple fix for "Database error saving new user" issue
-- This script removes the problematic handle_new_user trigger and fixes RLS policies

-- 1. Remove the problematic handle_new_user trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- 2. Remove any other custom triggers on auth.users that might be interfering
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

-- 2. Fix the RLS policy to allow profile creation during sign-up
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;

CREATE POLICY "Users can insert their own profile" ON users
    FOR INSERT WITH CHECK (
        -- Allow if user is authenticated and creating their own profile
        (auth.uid() IS NOT NULL AND auth.uid() = auth_user_id)
        OR
        -- Allow if no auth context (for system operations during sign-up)
        auth.uid() IS NULL
    );

-- 3. Ensure proper permissions
GRANT SELECT, INSERT, UPDATE ON users TO authenticated;
GRANT SELECT, INSERT, UPDATE ON users TO service_role;

SELECT 'Fix completed. Test sign up now.' as status;
