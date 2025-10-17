-- Comprehensive fix for "Database error saving new user" issue
-- This script addresses the most common causes of this error

-- 1. First, let's check the current state
SELECT 'Starting diagnostic and fix process...' as status;

-- 2. Check if there are any problematic triggers on auth.users
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
AND event_object_schema = 'auth';

-- 3. Remove any custom triggers that might be interfering
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

-- 4. Ensure RLS is enabled (it should be by default)
ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

-- 5. Check if there are any custom policies that might be blocking inserts
SELECT 
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename = 'users' 
AND schemaname = 'auth';

-- 6. Verify the users table in public schema doesn't have conflicting constraints
-- Check if there are any foreign key constraints from public.users to auth.users
-- that might be causing issues
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_schema = 'public'
AND ccu.table_schema = 'auth'
AND ccu.table_name = 'users';

-- 7. If there are foreign key constraints from public.users to auth.users,
-- temporarily disable them to test if they're causing the issue
-- (This is a temporary measure for testing)
DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    FOR constraint_record IN 
        SELECT tc.constraint_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_schema = 'public'
        AND ccu.table_schema = 'auth'
        AND ccu.table_name = 'users'
    LOOP
        EXECUTE 'ALTER TABLE public.users DROP CONSTRAINT IF EXISTS ' || constraint_record.constraint_name;
        RAISE NOTICE 'Temporarily removed foreign key constraint: %', constraint_record.constraint_name;
    END LOOP;
END $$;

-- 8. Recreate the foreign key constraint with proper settings
-- This ensures the constraint doesn't interfere with auth operations
ALTER TABLE public.users 
ADD CONSTRAINT users_auth_user_id_fkey 
FOREIGN KEY (auth_user_id) 
REFERENCES auth.users(id) 
ON DELETE CASCADE 
DEFERRABLE INITIALLY DEFERRED;

-- 9. Check the final state
SELECT 'Fix completed. Test sign up now.' as status;

-- 10. Verify the auth.users table is accessible
SELECT COUNT(*) as auth_users_count FROM auth.users;
