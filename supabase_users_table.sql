-- BAWASA Users Table
-- This script creates the users table for the BAWASA mobile app
-- This table stores additional user profile information separate from auth.users

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    phone VARCHAR(20),
    avatar_url TEXT,
    account_type VARCHAR(20) DEFAULT 'consumer' NOT NULL CHECK (account_type IN ('consumer', 'admin', 'staff')),
    is_active BOOLEAN DEFAULT true NOT NULL,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_auth_user_id ON users(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_account_type ON users(account_type);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);

-- Create a function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_users_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_users_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policies for RLS
-- Users can view their own profile
CREATE POLICY "Users can view their own profile" ON users
    FOR SELECT USING (auth.uid() = auth_user_id);

-- Users can insert their own profile (for new registrations)
-- This policy allows users to create their profile when they are authenticated
CREATE POLICY "Users can insert their own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = auth_user_id);

-- Users can update their own profile
CREATE POLICY "Users can update their own profile" ON users
    FOR UPDATE USING (auth.uid() = auth_user_id);

-- Admin policy (for future use - when admin roles are implemented)
-- CREATE POLICY "Admins can view all users" ON users
--     FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- Note: User profile creation is now handled by the application
-- when users are authenticated (after email confirmation).
-- This approach is more reliable than database triggers because:
-- 1. It ensures the user is properly authenticated before creating the profile
-- 2. It avoids RLS policy conflicts during trigger execution
-- 3. It provides better error handling and logging

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON users TO authenticated;

-- Comments for documentation
COMMENT ON TABLE users IS 'Stores additional user profile information separate from auth.users';
COMMENT ON COLUMN users.id IS 'Unique identifier for each user profile';
COMMENT ON COLUMN users.auth_user_id IS 'Reference to the auth.users table';
COMMENT ON COLUMN users.email IS 'User email address (duplicated from auth.users for easier querying)';
COMMENT ON COLUMN users.full_name IS 'User full name';
COMMENT ON COLUMN users.phone IS 'User phone number';
COMMENT ON COLUMN users.avatar_url IS 'URL to user avatar image';
COMMENT ON COLUMN users.account_type IS 'Type of account: consumer, admin, or staff';
COMMENT ON COLUMN users.is_active IS 'Whether the user account is active';
COMMENT ON COLUMN users.last_login_at IS 'Timestamp of last login';
COMMENT ON COLUMN users.created_at IS 'When the user profile was created';
COMMENT ON COLUMN users.updated_at IS 'When the user profile was last updated';
