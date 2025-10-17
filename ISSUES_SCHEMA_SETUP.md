# Issues Schema Setup Guide

This document provides instructions for setting up the issues functionality in Supabase for the BAWASA mobile application.

## Overview

The issues schema consists of three main tables that work together to provide comprehensive issue reporting and management functionality:

- **issues**: Main table storing issue reports and their status
- **issue_comments**: Communication and updates for each issue
- **issue_attachments**: File uploads and photos related to issues

## Database Setup

### 1. Prerequisites

Before setting up the issues schema, ensure you have already created:

- ✅ `users` table (from `supabase_users_table.sql`)

### 2. Run the SQL Script

Execute the SQL script `supabase_issues_schema.sql` in your Supabase SQL editor:

1. Go to your Supabase dashboard
2. Navigate to **SQL Editor**
3. Copy and paste the contents of `supabase_issues_schema.sql`
4. Click **Run** to execute the script

### 3. Verify Table Creation

After running the script, verify that the following have been created:

- ✅ `issues` table
- ✅ `issue_comments` table
- ✅ `issue_attachments` table
- ✅ Indexes for performance optimization
- ✅ Row Level Security (RLS) policies
- ✅ Triggers for automatic timestamp updates
- ✅ Functions for automatic issue number generation
- ✅ Views for easier querying

### 4. Test the Setup

You can test the setup by running these queries in the SQL editor:

```sql
-- Test creating an issue
INSERT INTO issues (user_id, title, description, issue_type, priority, location_address, contact_phone)
VALUES (
    auth.uid(),
    'Low Water Pressure in Kitchen',
    'The water pressure in the kitchen sink has been very low for the past 3 days. It takes a long time to fill a glass of water.',
    'low_water_pressure',
    'medium',
    '123 Main Street, City, State',
    '+1-555-123-4567'
);

-- Test adding a comment to the issue
INSERT INTO issue_comments (issue_id, user_id, comment_type, content)
VALUES (
    (SELECT id FROM issues WHERE title = 'Low Water Pressure in Kitchen' LIMIT 1),
    auth.uid(),
    'update',
    'Thank you for reporting this issue. We have scheduled a technician to visit your location tomorrow between 9 AM and 12 PM.'
);

-- Test querying issues with comments
SELECT * FROM issues_with_comments WHERE user_id = auth.uid();
```

## Table Structure

### issues Table

| Column                      | Type         | Description                                                                                                                |
| --------------------------- | ------------ | -------------------------------------------------------------------------------------------------------------------------- |
| `id`                        | UUID         | Primary key (auto-generated)                                                                                               |
| `user_id`                   | UUID         | Foreign key to auth.users                                                                                                  |
| `issue_number`              | VARCHAR(50)  | Unique issue number (auto-generated)                                                                                       |
| `title`                     | VARCHAR(255) | Brief title describing the issue                                                                                           |
| `description`               | TEXT         | Detailed description of the issue                                                                                          |
| `issue_type`                | VARCHAR(50)  | Category: water_leak, low_water_pressure, water_quality_issue, billing_dispute, meter_problem, service_interruption, other |
| `priority`                  | VARCHAR(20)  | Priority level: low, medium, high, urgent                                                                                  |
| `status`                    | VARCHAR(20)  | Status: open, in_progress, pending_customer, resolved, closed, cancelled                                                   |
| `location_address`          | TEXT         | Address where the issue occurred                                                                                           |
| `location_coordinates`      | POINT        | GPS coordinates of the issue location                                                                                      |
| `contact_phone`             | VARCHAR(20)  | Phone number for contact regarding this issue                                                                              |
| `contact_email`             | VARCHAR(255) | Email for contact regarding this issue                                                                                     |
| `estimated_resolution_date` | DATE         | Expected date when issue will be resolved                                                                                  |
| `actual_resolution_date`    | DATE         | Actual date when issue was resolved                                                                                        |
| `resolution_notes`          | TEXT         | Notes about how the issue was resolved                                                                                     |
| `assigned_to`               | UUID         | Staff member assigned to handle this issue                                                                                 |
| `created_at`                | TIMESTAMP    | When the issue was created                                                                                                 |
| `updated_at`                | TIMESTAMP    | When the issue was last updated                                                                                            |
| `resolved_at`               | TIMESTAMP    | When the issue was marked as resolved                                                                                      |
| `closed_at`                 | TIMESTAMP    | When the issue was closed                                                                                                  |

### issue_comments Table

| Column         | Type        | Description                                                       |
| -------------- | ----------- | ----------------------------------------------------------------- |
| `id`           | UUID        | Primary key (auto-generated)                                      |
| `issue_id`     | UUID        | Foreign key to issues table                                       |
| `user_id`      | UUID        | Foreign key to auth.users                                         |
| `comment_type` | VARCHAR(20) | Type: update, internal_note, customer_response, resolution_update |
| `content`      | TEXT        | Content of the comment                                            |
| `is_internal`  | BOOLEAN     | Whether this comment is internal (not visible to customers)       |
| `created_at`   | TIMESTAMP   | When the comment was created                                      |
| `updated_at`   | TIMESTAMP   | When the comment was last updated                                 |

### issue_attachments Table

| Column        | Type         | Description                                    |
| ------------- | ------------ | ---------------------------------------------- |
| `id`          | UUID         | Primary key (auto-generated)                   |
| `issue_id`    | UUID         | Foreign key to issues table                    |
| `user_id`     | UUID         | Foreign key to auth.users                      |
| `file_name`   | VARCHAR(255) | Original name of the uploaded file             |
| `file_path`   | TEXT         | Path to the file in storage                    |
| `file_size`   | BIGINT       | Size of the file in bytes                      |
| `mime_type`   | VARCHAR(100) | MIME type of the file                          |
| `file_type`   | VARCHAR(20)  | Category: image, document, video, audio, other |
| `description` | TEXT         | Optional description of the attachment         |
| `created_at`  | TIMESTAMP    | When the attachment was uploaded               |

## Key Features

### Automatic Issue Number Generation

The schema includes a trigger that automatically generates unique issue numbers in the format `ISS-YYYY-XXXX` (e.g., `ISS-2024-0001`).

### Automatic Status Timestamps

Triggers automatically update `resolved_at` and `closed_at` timestamps when issue status changes.

### Row Level Security (RLS)

All tables have RLS enabled with policies that ensure:

- Users can only view their own issues and related data
- Users can only create issues and comments for themselves
- Data isolation between different users

### Views for Easy Querying

Four convenient views are provided:

- `issues_with_user`: Issues with user information
- `issues_with_comments`: Issues with their comments as JSON
- `issues_with_attachments`: Issues with their attachments as JSON
- `issues_complete`: Comprehensive view with all related data

## Integration with Existing Tables

### Users Integration

- Issues reference `auth.users(id)` for user ownership
- User profile information is available through the `users` table
- Staff assignment uses the same user system

## Sample Queries

### Get User's Open Issues

```sql
SELECT * FROM issues_with_comments
WHERE user_id = auth.uid()
AND status IN ('open', 'in_progress', 'pending_customer')
ORDER BY priority DESC, created_at DESC;
```

### Get User's Recent Issues

```sql
SELECT * FROM issues_complete
WHERE user_id = auth.uid()
ORDER BY created_at DESC
LIMIT 10;
```

### Get Issues by Type

```sql
SELECT issue_type, COUNT(*) as count,
       COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved_count
FROM issues
WHERE user_id = auth.uid()
GROUP BY issue_type
ORDER BY count DESC;
```

### Get Issues Due for Resolution

```sql
SELECT * FROM issues_with_user
WHERE estimated_resolution_date <= CURRENT_DATE + INTERVAL '1 day'
AND status NOT IN ('resolved', 'closed', 'cancelled')
ORDER BY priority DESC, estimated_resolution_date ASC;
```

## Issue Types and Priorities

### Issue Types

- `water_leak`: Water leaks and pipe bursts
- `low_water_pressure`: Low water pressure issues
- `water_quality_issue`: Water quality problems
- `billing_dispute`: Billing and payment disputes
- `meter_problem`: Meter reading and functionality issues
- `service_interruption`: Service outages and interruptions
- `other`: Other issues not covered by the above categories

### Priorities

- `low`: Non-urgent issues that can be addressed during regular maintenance
- `medium`: Standard issues that should be addressed within a reasonable timeframe
- `high`: Important issues that require prompt attention
- `urgent`: Critical issues that require immediate attention

### Status Flow

1. `open` → Issue is newly reported
2. `in_progress` → Issue is being worked on
3. `pending_customer` → Waiting for customer response/action
4. `resolved` → Issue has been resolved
5. `closed` → Issue is closed (after customer confirmation)
6. `cancelled` → Issue was cancelled

## Next Steps

After setting up the issues schema:

1. **Create Dart entities** for issues, comments, and attachments
2. **Implement repositories** for data access
3. **Create use cases** for issue management
4. **Update the issues page** to use real data
5. **Implement file upload** functionality for attachments
6. **Add notification system** for issue updates

## File Storage Setup

For issue attachments to work properly, you'll need to set up Supabase Storage:

1. Go to **Storage** in your Supabase dashboard
2. Create a new bucket called `issue-attachments`
3. Set up RLS policies for the bucket
4. Configure file upload permissions

### Storage RLS Policy Example

```sql
-- Allow users to upload files for their own issues
CREATE POLICY "Users can upload attachments for their issues" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'issue-attachments' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to view attachments for their issues
CREATE POLICY "Users can view attachments for their issues" ON storage.objects
FOR SELECT USING (
    bucket_id = 'issue-attachments' AND
    auth.uid()::text = (storage.foldername(name))[1]
);
```

## Troubleshooting

### Common Issues

1. **Foreign Key Constraints**: Ensure users table exists before creating issues
2. **RLS Policies**: If you can't see data, check that RLS policies are correctly applied
3. **Triggers**: If issue numbers aren't generating, verify triggers are created and enabled
4. **File Storage**: Ensure storage bucket is created and policies are set up

### Verification Queries

```sql
-- Check if tables exist
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('issues', 'issue_comments', 'issue_attachments');

-- Check RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename IN ('issues', 'issue_comments', 'issue_attachments');

-- Check triggers
SELECT trigger_name, event_manipulation, action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
AND event_object_table IN ('issues', 'issue_comments', 'issue_attachments');

-- Test issue number generation
SELECT issue_number FROM issues ORDER BY created_at DESC LIMIT 5;
```
