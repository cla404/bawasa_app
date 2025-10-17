-- Migration script to populate user_id_ref column in meter_readings table
-- This script should be run after the schema changes but before removing the old user_id column

-- Step 1: Check if user_id_ref column exists and is populated
-- If not, populate it with the corresponding users.id values
UPDATE meter_readings 
SET user_id_ref = u.id 
FROM users u 
WHERE meter_readings.user_id = u.auth_user_id 
  AND meter_readings.user_id_ref IS NULL;

-- Step 2: Verify the migration
-- This query should return 0 rows if migration was successful
SELECT COUNT(*) as unmigrated_readings
FROM meter_readings 
WHERE user_id_ref IS NULL;

-- Step 3: Show migration results
SELECT 
    COUNT(*) as total_readings,
    COUNT(user_id_ref) as readings_with_user_id_ref,
    COUNT(*) - COUNT(user_id_ref) as readings_without_user_id_ref
FROM meter_readings;
