-- Migration script to add photo_url column to meter_readings table
-- Run this script if the meter_readings table already exists without the photo_url column

-- Add photo_url column to meter_readings table
ALTER TABLE meter_readings 
ADD COLUMN IF NOT EXISTS photo_url TEXT;

-- Add comment for the new column
COMMENT ON COLUMN meter_readings.photo_url IS 'URL of the photo taken of the meter reading';

-- Create storage bucket for meter reading photos (if it doesn't exist)
-- Note: This needs to be run in Supabase Dashboard or via Supabase CLI
-- INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
-- VALUES ('meter-readings', 'meter-readings', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp'])
-- ON CONFLICT (id) DO NOTHING;

-- Grant permissions for the storage bucket
-- GRANT SELECT ON storage.objects TO authenticated;
-- GRANT INSERT ON storage.objects TO authenticated;
-- GRANT UPDATE ON storage.objects TO authenticated;
-- GRANT DELETE ON storage.objects TO authenticated;
