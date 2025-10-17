# Users Table Setup Guide

This document provides instructions for setting up the users table functionality in Supabase for the BAWASA mobile application.

## Overview

The users table stores additional user profile information separate from the `auth.users` table. This allows for:

- Extended user profile data
- Better querying capabilities
- Custom user management features
- Integration with other application features

## Database Setup

### 1. Run the SQL Script

Execute the SQL script `supabase_users_table.sql` in your Supabase SQL editor:

1. Go to your Supabase dashboard
2. Navigate to **SQL Editor**
3. Copy and paste the contents of `supabase_users_table.sql`
4. Click **Run** to execute the script

### 2. Verify Table Creation

After running the script, verify that the following have been created:

- ✅ `users` table
- ✅ Indexes for performance optimization
- ✅ Row Level Security (RLS) policies
- ✅ Triggers for automatic timestamp updates
- ✅ Function to handle new user creation
- ✅ Trigger to automatically create user profiles

### 3. Test the Setup

You can test the setup by running a simple query in the SQL editor:

```sql
-- Test querying users
SELECT * FROM users ORDER BY created_at DESC;

-- Test the trigger by checking if new auth users get profiles
SELECT au.email, u.email as profile_email, u.full_name
FROM auth.users au
LEFT JOIN users u ON au.id = u.auth_user_id
ORDER BY au.created_at DESC;
```

## Table Structure

### users Table

| Column          | Type         | Description                        |
| --------------- | ------------ | ---------------------------------- |
| `id`            | UUID         | Primary key (auto-generated)       |
| `auth_user_id`  | UUID         | Foreign key to auth.users          |
| `email`         | VARCHAR(255) | User email address                 |
| `full_name`     | VARCHAR(255) | User full name                     |
| `phone`         | VARCHAR(20)  | User phone number                  |
| `avatar_url`    | TEXT         | URL to user avatar image           |
| `account_type`  | VARCHAR(20)  | Type: 'consumer', 'admin', 'staff' |
| `is_active`     | BOOLEAN      | Whether the account is active      |
| `last_login_at` | TIMESTAMP    | Timestamp of last login            |
| `created_at`    | TIMESTAMP    | When the profile was created       |
| `updated_at`    | TIMESTAMP    | When the profile was last updated  |

## Features Implemented

### Automatic User Profile Creation

- ✅ **Trigger-based creation**: When a user signs in for the first time, a profile is automatically created
- ✅ **Metadata extraction**: User metadata from auth.users is automatically copied to the users table
- ✅ **Last login tracking**: Each sign-in updates the last_login_at timestamp
- ✅ **Duplicate prevention**: The system checks if a profile already exists before creating a new one

### Row Level Security (RLS)

- ✅ **User isolation**: Users can only view and modify their own profiles
- ✅ **Secure operations**: All operations respect RLS policies
- ✅ **Admin ready**: Policies are prepared for future admin functionality

### Application Integration

- ✅ **Clean Architecture**: Follows the existing clean architecture pattern
- ✅ **BLoC Integration**: User profile creation is integrated into the AuthBloc
- ✅ **Dependency Injection**: All components are properly registered in the DI container
- ✅ **Error Handling**: Graceful error handling that doesn't break the auth flow

## How It Works

### 1. User Registration Flow

1. User signs up through the app
2. Supabase creates an entry in `auth.users`
3. User receives confirmation email
4. User clicks confirmation link
5. **NEW**: User profile is automatically created in `users` table

### 2. User Sign-In Flow

1. User signs in through the app
2. AuthBloc processes the sign-in
3. **NEW**: AuthBloc checks if user profile exists in `users` table
4. **NEW**: If profile doesn't exist, creates one; if it exists, updates last_login_at
5. User is authenticated and can use the app

### 3. Auth State Changes

1. Any auth state change (email confirmation, token refresh, etc.)
2. **NEW**: System automatically ensures user profile exists
3. **NEW**: Updates last login time for existing users

## Code Architecture

### Domain Layer

- `UserProfile` entity: Represents user profile data
- `UserRepository` interface: Defines user profile operations
- `CreateUserProfileUseCase`: Handles user profile creation logic

### Data Layer

- `SupabaseUserRepository`: Implements user profile operations using Supabase
- Database operations: Create, read, update user profiles

### Presentation Layer

- `AuthBloc`: Modified to include user profile creation
- Automatic profile management during authentication

## Testing

To test the implementation:

1. **Register a new user**: Sign up with a new email
2. **Confirm email**: Click the confirmation link
3. **Check database**: Verify user profile was created in `users` table
4. **Sign in**: Sign in with the new user
5. **Verify update**: Check that `last_login_at` was updated

## Troubleshooting

### Common Issues

1. **Profile not created**: Check if the trigger is properly installed
2. **RLS errors**: Ensure user is authenticated when accessing the table
3. **Metadata not copied**: Verify that user metadata is properly set during sign-up

### Debug Queries

```sql
-- Check if trigger exists
SELECT * FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'users';

-- Check recent user profiles
SELECT * FROM users ORDER BY created_at DESC LIMIT 10;
```

## Future Enhancements

- Admin user management interface
- User profile editing functionality
- Advanced user analytics
- User role management
- Bulk user operations
