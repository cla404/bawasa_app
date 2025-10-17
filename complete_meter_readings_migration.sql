-- Complete Migration Script for Meter Readings User ID Reference
-- This script handles the transition from user_id to user_id_ref

-- Step 1: Add the new user_id_ref column (if it doesn't exist)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'meter_readings' AND column_name = 'user_id_ref') THEN
        ALTER TABLE meter_readings ADD COLUMN user_id_ref UUID;
    END IF;
END $$;

-- Step 2: Populate user_id_ref with the corresponding users.id values
UPDATE meter_readings 
SET user_id_ref = u.id 
FROM users u 
WHERE meter_readings.user_id = u.auth_user_id 
  AND meter_readings.user_id_ref IS NULL;

-- Step 3: Make user_id_ref NOT NULL (only if all records have been migrated)
DO $$
DECLARE
    null_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO null_count 
    FROM meter_readings 
    WHERE user_id_ref IS NULL;
    
    IF null_count = 0 THEN
        ALTER TABLE meter_readings ALTER COLUMN user_id_ref SET NOT NULL;
        RAISE NOTICE 'user_id_ref column set to NOT NULL';
    ELSE
        RAISE NOTICE 'Cannot set user_id_ref to NOT NULL. % records still have NULL values', null_count;
    END IF;
END $$;

-- Step 4: Add foreign key constraint for user_id_ref
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'fk_meter_readings_user_id_ref') THEN
        ALTER TABLE meter_readings ADD CONSTRAINT fk_meter_readings_user_id_ref 
            FOREIGN KEY (user_id_ref) REFERENCES users(id) ON DELETE CASCADE;
        RAISE NOTICE 'Foreign key constraint added for user_id_ref';
    END IF;
END $$;

-- Step 5: Create index for user_id_ref
CREATE INDEX IF NOT EXISTS idx_meter_readings_user_id_ref ON meter_readings(user_id_ref);

-- Step 6: Update RLS policies to use user_id_ref
DROP POLICY IF EXISTS "Users can view their own meter readings" ON meter_readings;
DROP POLICY IF EXISTS "Users can insert their own meter readings" ON meter_readings;
DROP POLICY IF EXISTS "Users can update their own pending meter readings" ON meter_readings;
DROP POLICY IF EXISTS "Users can delete their own pending meter readings" ON meter_readings;

CREATE POLICY "Users can view their own meter readings" ON meter_readings
    FOR SELECT USING (
        user_id_ref IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert their own meter readings" ON meter_readings
    FOR INSERT WITH CHECK (
        user_id_ref IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own pending meter readings" ON meter_readings
    FOR UPDATE USING (
        user_id_ref IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        ) AND status = 'pending'
    );

CREATE POLICY "Users can delete their own pending meter readings" ON meter_readings
    FOR DELETE USING (
        user_id_ref IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        ) AND status = 'pending'
    );

-- Step 7: Update the view
DROP VIEW IF EXISTS meter_readings_with_user;
CREATE OR REPLACE VIEW meter_readings_with_user AS
SELECT 
    mr.*,
    u.email as user_email,
    u.full_name as user_name
FROM meter_readings mr
LEFT JOIN users u ON mr.user_id_ref = u.id;

-- Step 8: Verification queries
SELECT 
    'Migration Status' as status,
    COUNT(*) as total_readings,
    COUNT(user_id_ref) as readings_with_user_id_ref,
    COUNT(*) - COUNT(user_id_ref) as readings_without_user_id_ref
FROM meter_readings;

-- Step 9: Show any problematic records
SELECT 
    'Problematic Records' as issue_type,
    id,
    user_id,
    user_id_ref,
    meter_type,
    reading_date
FROM meter_readings 
WHERE user_id_ref IS NULL
LIMIT 10;

-- Step 10: Comments
COMMENT ON COLUMN meter_readings.user_id_ref IS 'Reference to the users table id (replaces user_id)';
COMMENT ON COLUMN meter_readings.user_id IS 'Legacy column - will be removed after migration is complete';
