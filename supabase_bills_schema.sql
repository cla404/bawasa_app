-- BAWASA Bills Schema
-- This script creates the bills, bill_items, and payments tables for the BAWASA mobile app
-- This schema integrates with the existing users and meter_readings tables

-- Create bills table
CREATE TABLE IF NOT EXISTS bills (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    bill_number VARCHAR(50) UNIQUE NOT NULL,
    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    tax_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    paid_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    balance_due DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status VARCHAR(20) DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'paid', 'overdue', 'cancelled')),
    payment_status VARCHAR(20) DEFAULT 'unpaid' NOT NULL CHECK (payment_status IN ('unpaid', 'partial', 'paid', 'refunded')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    CONSTRAINT valid_billing_period CHECK (billing_period_end >= billing_period_start),
    CONSTRAINT valid_due_date CHECK (due_date >= issue_date),
    CONSTRAINT valid_amounts CHECK (total_amount >= 0 AND paid_amount >= 0 AND balance_due >= 0)
);

-- Create bill_items table for individual charges
CREATE TABLE IF NOT EXISTS bill_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    bill_id UUID REFERENCES bills(id) ON DELETE CASCADE NOT NULL,
    item_type VARCHAR(50) NOT NULL CHECK (item_type IN ('water_usage', 'service_fee', 'late_fee', 'tax', 'discount', 'other')),
    description TEXT NOT NULL,
    quantity DECIMAL(10,3) DEFAULT 1.000,
    unit_price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    total_price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    meter_reading_id UUID REFERENCES meter_readings(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    CONSTRAINT valid_item_amounts CHECK (quantity >= 0 AND unit_price >= 0 AND total_price >= 0)
);

-- Create payments table
CREATE TABLE IF NOT EXISTS payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    bill_id UUID REFERENCES bills(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('cash', 'check', 'bank_transfer', 'mobile_money', 'credit_card', 'debit_card', 'other')),
    payment_reference VARCHAR(100),
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'completed' NOT NULL CHECK (status IN ('pending', 'completed', 'failed', 'cancelled', 'refunded')),
    notes TEXT,
    processed_by UUID REFERENCES auth.users(id),
    processed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    CONSTRAINT valid_payment_amount CHECK (amount > 0)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_bills_user_id ON bills(user_id);
CREATE INDEX IF NOT EXISTS idx_bills_bill_number ON bills(bill_number);
CREATE INDEX IF NOT EXISTS idx_bills_status ON bills(status);
CREATE INDEX IF NOT EXISTS idx_bills_payment_status ON bills(payment_status);
CREATE INDEX IF NOT EXISTS idx_bills_due_date ON bills(due_date);
CREATE INDEX IF NOT EXISTS idx_bills_billing_period ON bills(billing_period_start, billing_period_end);

CREATE INDEX IF NOT EXISTS idx_bill_items_bill_id ON bill_items(bill_id);
CREATE INDEX IF NOT EXISTS idx_bill_items_item_type ON bill_items(item_type);
CREATE INDEX IF NOT EXISTS idx_bill_items_meter_reading_id ON bill_items(meter_reading_id);

CREATE INDEX IF NOT EXISTS idx_payments_bill_id ON payments(bill_id);
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_payment_date ON payments(payment_date);

-- Create functions to automatically update timestamps
CREATE OR REPLACE FUNCTION update_bills_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION update_payments_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update timestamps
CREATE TRIGGER update_bills_updated_at 
    BEFORE UPDATE ON bills 
    FOR EACH ROW 
    EXECUTE FUNCTION update_bills_updated_at_column();

CREATE TRIGGER update_payments_updated_at 
    BEFORE UPDATE ON payments 
    FOR EACH ROW 
    EXECUTE FUNCTION update_payments_updated_at_column();

-- Create function to automatically calculate bill totals
CREATE OR REPLACE FUNCTION calculate_bill_totals()
RETURNS TRIGGER AS $$
DECLARE
    bill_subtotal DECIMAL(10,2);
    bill_tax DECIMAL(10,2);
    bill_total DECIMAL(10,2);
    bill_paid DECIMAL(10,2);
BEGIN
    -- Calculate subtotal from bill items
    SELECT COALESCE(SUM(total_price), 0.00) INTO bill_subtotal
    FROM bill_items 
    WHERE bill_id = COALESCE(NEW.bill_id, OLD.bill_id)
    AND item_type NOT IN ('tax', 'discount');
    
    -- Calculate tax amount
    SELECT COALESCE(SUM(total_price), 0.00) INTO bill_tax
    FROM bill_items 
    WHERE bill_id = COALESCE(NEW.bill_id, OLD.bill_id)
    AND item_type = 'tax';
    
    -- Calculate total amount
    bill_total := bill_subtotal + bill_tax;
    
    -- Calculate paid amount
    SELECT COALESCE(SUM(amount), 0.00) INTO bill_paid
    FROM payments 
    WHERE bill_id = COALESCE(NEW.bill_id, OLD.bill_id)
    AND status = 'completed';
    
    -- Update the bill
    UPDATE bills 
    SET 
        subtotal = bill_subtotal,
        tax_amount = bill_tax,
        total_amount = bill_total,
        paid_amount = bill_paid,
        balance_due = bill_total - bill_paid,
        payment_status = CASE 
            WHEN bill_paid = 0 THEN 'unpaid'
            WHEN bill_paid < bill_total THEN 'partial'
            WHEN bill_paid >= bill_total THEN 'paid'
        END,
        status = CASE 
            WHEN bill_paid >= bill_total THEN 'paid'
            WHEN due_date < CURRENT_DATE AND bill_paid < bill_total THEN 'overdue'
            ELSE 'pending'
        END
    WHERE id = COALESCE(NEW.bill_id, OLD.bill_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

-- Create triggers to automatically calculate bill totals
CREATE TRIGGER calculate_bill_totals_on_item_change
    AFTER INSERT OR UPDATE OR DELETE ON bill_items
    FOR EACH ROW
    EXECUTE FUNCTION calculate_bill_totals();

CREATE TRIGGER calculate_bill_totals_on_payment_change
    AFTER INSERT OR UPDATE OR DELETE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION calculate_bill_totals();

-- Enable Row Level Security (RLS)
ALTER TABLE bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE bill_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Create policies for RLS
-- Bills policies
CREATE POLICY "Users can view their own bills" ON bills
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own bills" ON bills
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own bills" ON bills
    FOR UPDATE USING (auth.uid() = user_id);

-- Bill items policies
CREATE POLICY "Users can view bill items for their bills" ON bill_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM bills 
            WHERE bills.id = bill_items.bill_id 
            AND bills.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert bill items for their bills" ON bill_items
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM bills 
            WHERE bills.id = bill_items.bill_id 
            AND bills.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update bill items for their bills" ON bill_items
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM bills 
            WHERE bills.id = bill_items.bill_id 
            AND bills.user_id = auth.uid()
        )
    );

-- Payments policies
CREATE POLICY "Users can view payments for their bills" ON payments
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert payments for their bills" ON payments
    FOR INSERT WITH CHECK (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM bills 
            WHERE bills.id = payments.bill_id 
            AND bills.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own payments" ON payments
    FOR UPDATE USING (auth.uid() = user_id);

-- Admin policies (for future use - when admin roles are implemented)
-- CREATE POLICY "Admins can view all bills" ON bills
--     FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
-- CREATE POLICY "Admins can view all bill items" ON bill_items
--     FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
-- CREATE POLICY "Admins can view all payments" ON payments
--     FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- Create views for easier querying
CREATE OR REPLACE VIEW bills_with_user AS
SELECT 
    b.*,
    u.email as user_email,
    u.full_name as user_name,
    u.phone as user_phone
FROM bills b
LEFT JOIN users u ON b.user_id = u.auth_user_id;

CREATE OR REPLACE VIEW bills_with_items AS
SELECT 
    b.*,
    COALESCE(
        json_agg(
            json_build_object(
                'id', bi.id,
                'item_type', bi.item_type,
                'description', bi.description,
                'quantity', bi.quantity,
                'unit_price', bi.unit_price,
                'total_price', bi.total_price,
                'meter_reading_id', bi.meter_reading_id
            ) ORDER BY bi.created_at
        ) FILTER (WHERE bi.id IS NOT NULL),
        '[]'::json
    ) as items
FROM bills b
LEFT JOIN bill_items bi ON b.id = bi.bill_id
GROUP BY b.id;

CREATE OR REPLACE VIEW bills_with_payments AS
SELECT 
    b.*,
    COALESCE(
        json_agg(
            json_build_object(
                'id', p.id,
                'payment_method', p.payment_method,
                'payment_reference', p.payment_reference,
                'amount', p.amount,
                'payment_date', p.payment_date,
                'status', p.status,
                'notes', p.notes,
                'processed_at', p.processed_at
            ) ORDER BY p.payment_date DESC
        ) FILTER (WHERE p.id IS NOT NULL),
        '[]'::json
    ) as payments
FROM bills b
LEFT JOIN payments p ON b.id = p.bill_id
GROUP BY b.id;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON bills TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON bill_items TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON payments TO authenticated;
GRANT SELECT ON bills_with_user TO authenticated;
GRANT SELECT ON bills_with_items TO authenticated;
GRANT SELECT ON bills_with_payments TO authenticated;

-- Comments for documentation
COMMENT ON TABLE bills IS 'Stores water bills for users';
COMMENT ON COLUMN bills.id IS 'Unique identifier for each bill';
COMMENT ON COLUMN bills.user_id IS 'Reference to the user who owns this bill';
COMMENT ON COLUMN bills.bill_number IS 'Unique bill number for reference';
COMMENT ON COLUMN bills.billing_period_start IS 'Start date of the billing period';
COMMENT ON COLUMN bills.billing_period_end IS 'End date of the billing period';
COMMENT ON COLUMN bills.issue_date IS 'Date when the bill was issued';
COMMENT ON COLUMN bills.due_date IS 'Date when payment is due';
COMMENT ON COLUMN bills.subtotal IS 'Subtotal amount before tax';
COMMENT ON COLUMN bills.tax_amount IS 'Tax amount';
COMMENT ON COLUMN bills.total_amount IS 'Total bill amount including tax';
COMMENT ON COLUMN bills.paid_amount IS 'Total amount paid';
COMMENT ON COLUMN bills.balance_due IS 'Remaining balance to be paid';
COMMENT ON COLUMN bills.status IS 'Bill status: pending, paid, overdue, cancelled';
COMMENT ON COLUMN bills.payment_status IS 'Payment status: unpaid, partial, paid, refunded';

COMMENT ON TABLE bill_items IS 'Stores individual line items for each bill';
COMMENT ON COLUMN bill_items.id IS 'Unique identifier for each bill item';
COMMENT ON COLUMN bill_items.bill_id IS 'Reference to the parent bill';
COMMENT ON COLUMN bill_items.item_type IS 'Type of charge: water_usage, service_fee, late_fee, tax, discount, other';
COMMENT ON COLUMN bill_items.description IS 'Description of the charge';
COMMENT ON COLUMN bill_items.quantity IS 'Quantity of units';
COMMENT ON COLUMN bill_items.unit_price IS 'Price per unit';
COMMENT ON COLUMN bill_items.total_price IS 'Total price for this item';
COMMENT ON COLUMN bill_items.meter_reading_id IS 'Reference to meter reading if applicable';

COMMENT ON TABLE payments IS 'Stores payment records for bills';
COMMENT ON COLUMN payments.id IS 'Unique identifier for each payment';
COMMENT ON COLUMN payments.bill_id IS 'Reference to the bill being paid';
COMMENT ON COLUMN payments.user_id IS 'Reference to the user making the payment';
COMMENT ON COLUMN payments.payment_method IS 'Method of payment';
COMMENT ON COLUMN payments.payment_reference IS 'Reference number for the payment';
COMMENT ON COLUMN payments.amount IS 'Amount of the payment';
COMMENT ON COLUMN payments.payment_date IS 'Date when payment was made';
COMMENT ON COLUMN payments.status IS 'Payment status: pending, completed, failed, cancelled, refunded';
COMMENT ON COLUMN payments.processed_by IS 'User who processed the payment';
COMMENT ON COLUMN payments.processed_at IS 'When the payment was processed';
