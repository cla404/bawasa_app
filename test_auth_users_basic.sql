-- Simple test to check if basic auth operations work
-- This will help isolate whether the issue is with the database or the app

-- Test 1: Check if we can query auth.users table
SELECT COUNT(*) as user_count FROM auth.users;

-- Test 2: Check if there are any recent users
SELECT 
    id,
    email,
    created_at,
    email_confirmed_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 3;

-- Test 3: Check if there are any error logs in the auth schema
-- (This might not be accessible depending on permissions)

-- Test 4: Verify the auth.users table structure
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'auth' 
AND table_name = 'users'
ORDER BY ordinal_position;

-- Test 5: Check for any foreign key constraints that might be causing issues
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
AND tc.table_schema = 'auth'
AND tc.table_name = 'users';

SELECT 'Diagnostic tests completed. Review results above.' as status;
