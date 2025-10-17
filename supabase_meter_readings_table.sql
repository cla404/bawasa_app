-- BAWASA Meter Readings Table
-- This script creates the meter_readings table for the BAWASA mobile app

-- Create meter_readings table
CREATE TABLE IF NOT EXISTS meter_readings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id_ref UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    meter_type VARCHAR(20) DEFAULT 'Water' NOT NULL,
    reading_value DECIMAL(10,2) NOT NULL,
    reading_date DATE NOT NULL,
    notes TEXT,
    photo_url TEXT,
    status VARCHAR(20) DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'confirmed', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    confirmed_by UUID REFERENCES auth.users(id),
    confirmed_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_meter_readings_user_id_ref ON meter_readings(user_id_ref);
CREATE INDEX IF NOT EXISTS idx_meter_readings_reading_date ON meter_readings(reading_date);
CREATE INDEX IF NOT EXISTS idx_meter_readings_status ON meter_readings(status);
CREATE INDEX IF NOT EXISTS idx_meter_readings_meter_type ON meter_readings(meter_type);

-- Create a function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_meter_readings_updated_at 
    BEFORE UPDATE ON meter_readings 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE meter_readings ENABLE ROW LEVEL SECURITY;

-- Create policies for RLS
-- Users can only see their own meter readings
CREATE POLICY "Users can view their own meter readings" ON meter_readings
    FOR SELECT USING (
        user_id_ref IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

-- Users can insert their own meter readings
CREATE POLICY "Users can insert their own meter readings" ON meter_readings
    FOR INSERT WITH CHECK (
        user_id_ref IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    );

-- Users can update their own meter readings (only if status is pending)
CREATE POLICY "Users can update their own pending meter readings" ON meter_readings
    FOR UPDATE USING (
        user_id_ref IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        ) AND status = 'pending'
    );

-- Users can delete their own meter readings (only if status is pending)
CREATE POLICY "Users can delete their own pending meter readings" ON meter_readings
    FOR DELETE USING (
        user_id_ref IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        ) AND status = 'pending'
    );

-- Admin policy (for future use - when admin roles are implemented)
-- CREATE POLICY "Admins can view all meter readings" ON meter_readings
--     FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- Create a view for easier querying with user information
CREATE OR REPLACE VIEW meter_readings_with_user AS
SELECT 
    mr.*,
    u.email as user_email,
    u.full_name as user_name
FROM meter_readings mr
LEFT JOIN users u ON mr.user_id_ref = u.id;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON meter_readings TO authenticated;
GRANT SELECT ON meter_readings_with_user TO authenticated;

-- Insert some sample data (optional - remove in production)
-- INSERT INTO meter_readings (user_id, meter_type, reading_value, reading_date, notes, status)
-- VALUES 
--     (auth.uid(), 'Water', 1250.00, '2024-12-15', 'Regular monthly reading', 'confirmed'),
--     (auth.uid(), 'Water', 1180.00, '2024-11-15', 'Regular monthly reading', 'confirmed'),
--     (auth.uid(), 'Water', 1110.00, '2024-10-15', 'Regular monthly reading', 'confirmed');

-- Comments for documentation
COMMENT ON TABLE meter_readings IS 'Stores water meter readings submitted by users';
COMMENT ON COLUMN meter_readings.id IS 'Unique identifier for each meter reading';
COMMENT ON COLUMN meter_readings.user_id_ref IS 'Reference to the users table id';
COMMENT ON COLUMN meter_readings.meter_type IS 'Type of meter (currently only Water)';
COMMENT ON COLUMN meter_readings.reading_value IS 'The actual meter reading value in cubic meters';
COMMENT ON COLUMN meter_readings.reading_date IS 'Date when the reading was taken';
COMMENT ON COLUMN meter_readings.notes IS 'Optional notes about the reading';
COMMENT ON COLUMN meter_readings.photo_url IS 'URL of the photo taken of the meter reading';
COMMENT ON COLUMN meter_readings.status IS 'Status of the reading: pending, confirmed, or rejected';
COMMENT ON COLUMN meter_readings.confirmed_by IS 'User who confirmed the reading (admin)';
COMMENT ON COLUMN meter_readings.confirmed_at IS 'Timestamp when the reading was confirmed';
