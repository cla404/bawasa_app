-- Clean up script to remove any problematic triggers or constraints
-- that might be causing the "Database error saving new user" issue

-- 1. Drop any triggers on auth.users table that might be causing issues
DO $$
DECLARE
    trigger_record RECORD;
BEGIN
    FOR trigger_record IN 
        SELECT trigger_name 
        FROM information_schema.triggers 
        WHERE event_object_table = 'users' 
        AND event_object_schema = 'auth'
        AND trigger_name != 'on_auth_user_created' -- Keep the default Supabase trigger
    LOOP
        EXECUTE 'DROP TRIGGER IF EXISTS ' || trigger_record.trigger_name || ' ON auth.users';
        RAISE NOTICE 'Dropped trigger: %', trigger_record.trigger_name;
    END LOOP;
END $$;

-- 2. Check if there are any custom constraints that might be problematic
-- (Most constraints on auth.users are system-defined and shouldn't be removed)

-- 3. Ensure RLS is properly configured (it should be enabled by default)
ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

-- 4. Check if there are any problematic policies
-- (Supabase manages auth.users policies, so we shouldn't modify them)

-- 5. Verify the table structure is correct
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'auth' 
AND table_name = 'users'
ORDER BY ordinal_position;

-- 6. Test if we can insert a test user (this will fail but show us the error)
-- DO NOT RUN THIS IN PRODUCTION - it's just for testing
/*
INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    'test@example.com',
    crypt('password123', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
);
*/

SELECT 'Cleanup completed. Check the results above for any issues.' as status;
