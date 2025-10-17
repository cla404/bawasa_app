# BAWASA Management System - Supabase Setup

## Prerequisites

1. Create a Supabase account at [supabase.com](https://supabase.com)
2. Create a new project in your Supabase dashboard
3. Get your project URL and anon key from the project settings

## Setup Instructions

### 1. Create Environment File

Create a `.env` file in the root directory (`bawasa_system/.env`) with the following content:

```
SUPABASE_URL=your_supabase_project_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

Replace the placeholder values with your actual Supabase credentials:

- `SUPABASE_URL`: Your project URL (e.g., `https://your-project-id.supabase.co`)
- `SUPABASE_ANON_KEY`: Your project's anonymous key (found in Project Settings > API)

**Important:** The `.env` file has been added to the assets section in `pubspec.yaml`, so Flutter will include it in the build. If you don't create this file, the app will still run but will use placeholder values and show a warning message.

### 2. Install Dependencies

Run the following command to install the required packages:

```bash
flutter pub get
```

### 3. Configure Supabase Authentication

In your Supabase dashboard:

1. Go to **Authentication** > **Settings**
2. Configure your site URL (for development: `http://localhost:3000`)
3. Add your redirect URLs if needed
4. Enable email confirmations if desired

### 4. Database Setup

The authentication will automatically create the necessary tables in Supabase. No additional setup is required for basic authentication.

### 5. Run the Application

```bash
flutter run
```

## Features Implemented

### Sign Up Page

- ✅ Full name field with validation
- ✅ Email field with regex validation
- ✅ Phone number field (optional) with validation
- ✅ Password field with strength requirements
- ✅ Confirm password field with matching validation
- ✅ Terms and conditions checkbox
- ✅ Supabase authentication integration
- ✅ Loading states and error handling
- ✅ Success feedback and navigation
- ✅ Social sign-up placeholders (Google, Microsoft)

### Sign In Page

- ✅ Email and password fields
- ✅ Remember me functionality
- ✅ Forgot password link
- ✅ Supabase authentication integration
- ✅ Loading states and error handling
- ✅ Social sign-in placeholders

## Authentication Flow

1. User fills out the sign-up form
2. Form validation ensures data quality
3. User data is sent to Supabase Auth
4. Supabase creates user account and sends verification email
5. User is redirected to sign-in page
6. User can sign in with their credentials

## Security Features

- Password strength validation (8+ chars, uppercase, lowercase, number)
- Email format validation
- Phone number format validation
- Terms and conditions agreement required
- Secure password handling with visibility toggle
- Proper error handling and user feedback

## Next Steps

- Configure email templates in Supabase
- Set up social authentication providers
- Implement password reset functionality
- Add user profile management
- Set up role-based access control
