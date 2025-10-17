# Meter Readings User ID Reference Migration

## Overview

This migration updates the meter_readings table to use `user_id_ref` that references the `users.id` instead of directly referencing `auth.users.id`. This ensures proper foreign key relationships and data integrity.

## Changes Made

### 1. Database Schema Updates

- **File**: `supabase_meter_readings_table.sql`
- **Changes**:
  - Renamed `user_id` column to `user_id_ref`
  - Updated foreign key reference from `auth.users(id)` to `users(id)`
  - Updated indexes to use `user_id_ref`
  - Updated RLS policies to properly reference users table
  - Updated view to join with users table instead of auth.users

### 2. Entity Updates

- **File**: `lib/domain/entities/meter_reading.dart`
- **Changes**:
  - Renamed `userId` field to `user_id_ref`
  - Updated all JSON serialization methods
  - Updated equality operators and hashCode

### 3. Repository Implementation Updates

- **File**: `lib/data/repositories/meter_reading_repository_impl.dart`
- **Changes**:
  - Updated `submitMeterReading` method to fetch user profile ID from users table
  - Added proper error handling for missing user profiles
  - Uses `user_id_ref` instead of auth user ID

### 4. Use Case Updates

- **File**: `lib/domain/usecases/meter_reading_usecases.dart`
- **Changes**:
  - Updated MeterReading creation to use `user_id_ref` field

## Immediate Fix for Current Issue

The error you're seeing is because the database still has the old `user_id` column with a NOT NULL constraint, but we're only inserting `user_id_ref`.

**I've updated the code to handle this transition period by inserting both columns temporarily.**

**Run this SQL script in your Supabase SQL editor to complete the migration:**

```sql
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

-- Step 8: Verification
SELECT
    'Migration Status' as status,
    COUNT(*) as total_readings,
    COUNT(user_id_ref) as readings_with_user_id_ref,
    COUNT(*) - COUNT(user_id_ref) as readings_without_user_id_ref
FROM meter_readings;
```

## Database Migration Script

To apply these changes to an existing database, run the following SQL script:

```sql
-- Step 1: Add the new user_id_ref column
ALTER TABLE meter_readings ADD COLUMN user_id_ref UUID;

-- Step 2: Populate user_id_ref with the corresponding users.id values
UPDATE meter_readings
SET user_id_ref = u.id
FROM users u
WHERE meter_readings.user_id = u.auth_user_id;

-- Step 3: Make user_id_ref NOT NULL
ALTER TABLE meter_readings ALTER COLUMN user_id_ref SET NOT NULL;

-- Step 4: Add foreign key constraint
ALTER TABLE meter_readings ADD CONSTRAINT fk_meter_readings_user_id_ref
    FOREIGN KEY (user_id_ref) REFERENCES users(id) ON DELETE CASCADE;

-- Step 5: Create new index
CREATE INDEX IF NOT EXISTS idx_meter_readings_user_id_ref ON meter_readings(user_id_ref);

-- Step 6: Drop old constraints and column
ALTER TABLE meter_readings DROP CONSTRAINT IF EXISTS meter_readings_user_id_fkey;
DROP INDEX IF EXISTS idx_meter_readings_user_id;
ALTER TABLE meter_readings DROP COLUMN user_id;

-- Step 7: Update RLS policies
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

-- Step 8: Update the view
DROP VIEW IF EXISTS meter_readings_with_user;
CREATE OR REPLACE VIEW meter_readings_with_user AS
SELECT
    mr.*,
    u.email as user_email,
    u.full_name as user_name
FROM meter_readings mr
LEFT JOIN users u ON mr.user_id_ref = u.id;

-- Step 9: Update comments
COMMENT ON COLUMN meter_readings.user_id_ref IS 'Reference to the users table id';
```

## Testing

After applying the migration:

1. **Test meter reading submission**: Verify that new meter readings are created with proper `user_id_ref` values
2. **Test data retrieval**: Ensure existing meter readings can still be retrieved
3. **Test RLS policies**: Verify that users can only see their own meter readings
4. **Test foreign key constraints**: Ensure referential integrity is maintained

## Rollback Plan

If rollback is needed:

```sql
-- Add back the old user_id column
ALTER TABLE meter_readings ADD COLUMN user_id UUID;

-- Populate with auth user IDs
UPDATE meter_readings
SET user_id = u.auth_user_id
FROM users u
WHERE meter_readings.user_id_ref = u.id;

-- Make it NOT NULL and add constraint
ALTER TABLE meter_readings ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE meter_readings ADD CONSTRAINT fk_meter_readings_user_id
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Drop new column and constraints
ALTER TABLE meter_readings DROP CONSTRAINT IF EXISTS fk_meter_readings_user_id_ref;
DROP INDEX IF EXISTS idx_meter_readings_user_id_ref;
ALTER TABLE meter_readings DROP COLUMN user_id_ref;
```

## Benefits

1. **Proper Data Modeling**: Clear separation between authentication and user profile data
2. **Referential Integrity**: Foreign key constraints ensure data consistency
3. **Better Performance**: Direct joins with users table instead of auth.users
4. **Maintainability**: Easier to manage user-related data in a single table
