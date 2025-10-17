# Bills Schema Setup Guide

This document provides instructions for setting up the bills functionality in Supabase for the BAWASA mobile application.

## Overview

The bills schema consists of three main tables that work together to provide comprehensive billing functionality:

- **bills**: Main table storing bill information and totals
- **bill_items**: Individual line items for each bill (water usage, fees, taxes, etc.)
- **payments**: Payment records and transaction history

## Database Setup

### 1. Prerequisites

Before setting up the bills schema, ensure you have already created:

- ✅ `users` table (from `supabase_users_table.sql`)
- ✅ `meter_readings` table (from `supabase_meter_readings_table.sql`)

### 2. Run the SQL Script

Execute the SQL script `supabase_bills_schema.sql` in your Supabase SQL editor:

1. Go to your Supabase dashboard
2. Navigate to **SQL Editor**
3. Copy and paste the contents of `supabase_bills_schema.sql`
4. Click **Run** to execute the script

### 3. Verify Table Creation

After running the script, verify that the following have been created:

- ✅ `bills` table
- ✅ `bill_items` table
- ✅ `payments` table
- ✅ Indexes for performance optimization
- ✅ Row Level Security (RLS) policies
- ✅ Triggers for automatic timestamp updates
- ✅ Functions for automatic bill calculations
- ✅ Views for easier querying

### 4. Test the Setup

You can test the setup by running these queries in the SQL editor:

```sql
-- Test creating a bill
INSERT INTO bills (user_id, bill_number, billing_period_start, billing_period_end, issue_date, due_date)
VALUES (
    auth.uid(),
    'BILL-2024-001',
    '2024-11-15',
    '2024-12-15',
    '2024-12-16',
    '2025-01-15'
);

-- Test adding bill items
INSERT INTO bill_items (bill_id, item_type, description, quantity, unit_price, total_price)
VALUES
    ((SELECT id FROM bills WHERE bill_number = 'BILL-2024-001'), 'water_usage', 'Water consumption (50 cubic meters)', 50.000, 0.85, 42.50),
    ((SELECT id FROM bills WHERE bill_number = 'BILL-2024-001'), 'service_fee', 'Monthly service fee', 1.000, 3.00, 3.00),
    ((SELECT id FROM bills WHERE bill_number = 'BILL-2024-001'), 'tax', 'VAT (10%)', 1.000, 4.55, 4.55);

-- Test adding a payment
INSERT INTO payments (bill_id, user_id, payment_method, amount, payment_date, status)
VALUES (
    (SELECT id FROM bills WHERE bill_number = 'BILL-2024-001'),
    auth.uid(),
    'bank_transfer',
    50.05,
    '2024-12-20',
    'completed'
);

-- Test querying bills with items and payments
SELECT * FROM bills_with_items WHERE user_id = auth.uid();
```

## Table Structure

### bills Table

| Column                 | Type          | Description                                     |
| ---------------------- | ------------- | ----------------------------------------------- |
| `id`                   | UUID          | Primary key (auto-generated)                    |
| `user_id`              | UUID          | Foreign key to auth.users                       |
| `bill_number`          | VARCHAR(50)   | Unique bill number for reference                |
| `billing_period_start` | DATE          | Start date of the billing period                |
| `billing_period_end`   | DATE          | End date of the billing period                  |
| `issue_date`           | DATE          | Date when the bill was issued                   |
| `due_date`             | DATE          | Date when payment is due                        |
| `subtotal`             | DECIMAL(10,2) | Subtotal amount before tax                      |
| `tax_amount`           | DECIMAL(10,2) | Tax amount                                      |
| `total_amount`         | DECIMAL(10,2) | Total bill amount including tax                 |
| `paid_amount`          | DECIMAL(10,2) | Total amount paid                               |
| `balance_due`          | DECIMAL(10,2) | Remaining balance to be paid                    |
| `status`               | VARCHAR(20)   | Bill status: pending, paid, overdue, cancelled  |
| `payment_status`       | VARCHAR(20)   | Payment status: unpaid, partial, paid, refunded |
| `notes`                | TEXT          | Optional notes about the bill                   |
| `created_at`           | TIMESTAMP     | When the bill was created                       |
| `updated_at`           | TIMESTAMP     | When the bill was last updated                  |
| `created_by`           | UUID          | User who created the bill                       |

### bill_items Table

| Column             | Type          | Description                                                    |
| ------------------ | ------------- | -------------------------------------------------------------- |
| `id`               | UUID          | Primary key (auto-generated)                                   |
| `bill_id`          | UUID          | Foreign key to bills table                                     |
| `item_type`        | VARCHAR(50)   | Type: water_usage, service_fee, late_fee, tax, discount, other |
| `description`      | TEXT          | Description of the charge                                      |
| `quantity`         | DECIMAL(10,3) | Quantity of units                                              |
| `unit_price`       | DECIMAL(10,2) | Price per unit                                                 |
| `total_price`      | DECIMAL(10,2) | Total price for this item                                      |
| `meter_reading_id` | UUID          | Reference to meter reading if applicable                       |
| `created_at`       | TIMESTAMP     | When the item was created                                      |

### payments Table

| Column              | Type          | Description                                                                      |
| ------------------- | ------------- | -------------------------------------------------------------------------------- |
| `id`                | UUID          | Primary key (auto-generated)                                                     |
| `bill_id`           | UUID          | Foreign key to bills table                                                       |
| `user_id`           | UUID          | Foreign key to auth.users                                                        |
| `payment_method`    | VARCHAR(50)   | Method: cash, check, bank_transfer, mobile_money, credit_card, debit_card, other |
| `payment_reference` | VARCHAR(100)  | Reference number for the payment                                                 |
| `amount`            | DECIMAL(10,2) | Amount of the payment                                                            |
| `payment_date`      | DATE          | Date when payment was made                                                       |
| `status`            | VARCHAR(20)   | Status: pending, completed, failed, cancelled, refunded                          |
| `notes`             | TEXT          | Optional notes about the payment                                                 |
| `processed_by`      | UUID          | User who processed the payment                                                   |
| `processed_at`      | TIMESTAMP     | When the payment was processed                                                   |
| `created_at`        | TIMESTAMP     | When the payment record was created                                              |
| `updated_at`        | TIMESTAMP     | When the payment record was last updated                                         |

## Key Features

### Automatic Calculations

The schema includes triggers that automatically:

- Calculate bill totals when items are added/updated/deleted
- Update payment status based on payments received
- Update bill status (pending → paid → overdue)
- Maintain balance due calculations

### Row Level Security (RLS)

All tables have RLS enabled with policies that ensure:

- Users can only view their own bills and payments
- Users can only create bills and payments for themselves
- Data isolation between different users

### Views for Easy Querying

Three convenient views are provided:

- `bills_with_user`: Bills with user information
- `bills_with_items`: Bills with their line items as JSON
- `bills_with_payments`: Bills with their payment history as JSON

## Integration with Existing Tables

### Users Integration

- Bills reference `auth.users(id)` for user ownership
- User profile information is available through the `users` table

### Meter Readings Integration

- Bill items can reference specific meter readings
- This allows tracking which meter readings contributed to which bills

## Sample Queries

### Get User's Current Bills

```sql
SELECT * FROM bills_with_items
WHERE user_id = auth.uid()
AND status IN ('pending', 'overdue')
ORDER BY due_date ASC;
```

### Get User's Payment History

```sql
SELECT b.bill_number, p.*
FROM payments p
JOIN bills b ON p.bill_id = b.id
WHERE p.user_id = auth.uid()
ORDER BY p.payment_date DESC;
```

### Get Bills Due Soon

```sql
SELECT * FROM bills_with_user
WHERE user_id = auth.uid()
AND due_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
AND status = 'pending';
```

## Next Steps

After setting up the bills schema:

1. **Create Dart entities** for bills, bill items, and payments
2. **Implement repositories** for data access
3. **Create use cases** for bill management
4. **Update the billing page** to use real data
5. **Implement payment processing** integration

## Troubleshooting

### Common Issues

1. **Foreign Key Constraints**: Ensure users and meter_readings tables exist before creating bills
2. **RLS Policies**: If you can't see data, check that RLS policies are correctly applied
3. **Triggers**: If calculations aren't updating, verify triggers are created and enabled

### Verification Queries

```sql
-- Check if tables exist
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('bills', 'bill_items', 'payments');

-- Check RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename IN ('bills', 'bill_items', 'payments');

-- Check triggers
SELECT trigger_name, event_manipulation, action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
AND event_object_table IN ('bills', 'bill_items', 'payments');
```
