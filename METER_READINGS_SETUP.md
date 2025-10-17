# Meter Readings Supabase Setup

This document provides instructions for setting up the meter readings functionality in Supabase for the BAWASA mobile application.

## Database Setup

### 1. Run the SQL Script

Execute the SQL script `supabase_meter_readings_table.sql` in your Supabase SQL editor:

1. Go to your Supabase dashboard
2. Navigate to **SQL Editor**
3. Copy and paste the contents of `supabase_meter_readings_table.sql`
4. Click **Run** to execute the script

### 2. Verify Table Creation

After running the script, verify that the following have been created:

- ✅ `meter_readings` table
- ✅ Indexes for performance optimization
- ✅ Row Level Security (RLS) policies
- ✅ Triggers for automatic timestamp updates
- ✅ `meter_readings_with_user` view

### 3. Test the Setup

You can test the setup by running a simple query in the SQL editor:

```sql
-- Test inserting a meter reading (replace with actual user ID)
INSERT INTO meter_readings (meter_type, reading_value, reading_date, notes)
VALUES ('Water', 1250.00, '2024-12-15', 'Test reading');

-- Test querying meter readings
SELECT * FROM meter_readings ORDER BY reading_date DESC;
```

## Table Structure

### meter_readings Table

| Column          | Type          | Description                                |
| --------------- | ------------- | ------------------------------------------ |
| `id`            | UUID          | Primary key (auto-generated)               |
| `user_id`       | UUID          | Foreign key to auth.users                  |
| `meter_type`    | VARCHAR(20)   | Type of meter (default: 'Water')           |
| `reading_value` | DECIMAL(10,2) | Meter reading value in cubic meters        |
| `reading_date`  | DATE          | Date when reading was taken                |
| `notes`         | TEXT          | Optional notes about the reading           |
| `status`        | VARCHAR(20)   | Status: 'pending', 'confirmed', 'rejected' |
| `created_at`    | TIMESTAMP     | When record was created                    |
| `updated_at`    | TIMESTAMP     | When record was last updated               |
| `confirmed_by`  | UUID          | User who confirmed the reading             |
| `confirmed_at`  | TIMESTAMP     | When reading was confirmed                 |

## Security Features

### Row Level Security (RLS)

The table has RLS enabled with the following policies:

1. **Users can view their own meter readings** - Users can only see meter readings they submitted
2. **Users can insert their own meter readings** - Users can only create meter readings for themselves
3. **Users can update their own pending meter readings** - Users can only modify readings with 'pending' status
4. **Users can delete their own pending meter readings** - Users can only delete readings with 'pending' status

### Data Validation

- `meter_type` is constrained to 'Water' (can be extended later)
- `status` is constrained to 'pending', 'confirmed', or 'rejected'
- `reading_value` must be a positive decimal number
- `reading_date` cannot be in the future

## Integration with Flutter App

### Dependencies Required

Make sure these packages are in your `pubspec.yaml`:

```yaml
dependencies:
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  supabase_flutter: ^2.0.0
```

### Usage in Flutter

1. **Initialize the BLoC** in your dependency injection setup
2. **Use BlocProvider** to provide the MeterReadingBloc to your widget tree
3. **Listen to state changes** using BlocListener or BlocBuilder
4. **Dispatch events** to submit, update, or delete meter readings

### Example Usage

```dart
// Submit a new meter reading
context.read<MeterReadingBloc>().add(
  SubmitMeterReading(
    meterType: 'Water',
    readingValue: 1250.0,
    readingDate: DateTime.now(),
    notes: 'Monthly reading',
  ),
);

// Load user's meter readings
context.read<MeterReadingBloc>().add(LoadMeterReadings());
```

## Future Enhancements

### Admin Features

When implementing admin functionality, you can:

1. **Add admin policies** to allow admins to view all meter readings
2. **Create admin endpoints** for confirming/rejecting readings
3. **Add bulk operations** for processing multiple readings

### Additional Features

1. **Meter types** - Extend to support electricity, gas, etc.
2. **Reading validation** - Add business rules for reading validation
3. **Notifications** - Send notifications for pending readings
4. **Reports** - Generate consumption reports and analytics

## Troubleshooting

### Common Issues

1. **Permission denied** - Ensure RLS policies are correctly set up
2. **Foreign key errors** - Make sure user exists in auth.users table
3. **Date format errors** - Use YYYY-MM-DD format for dates
4. **Decimal precision** - Reading values should not exceed 10 digits with 2 decimal places

### Debug Queries

```sql
-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'meter_readings';

-- Check table structure
\d meter_readings;

-- Check indexes
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'meter_readings';
```

## Support

For issues or questions regarding the meter readings setup, please refer to:

- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
