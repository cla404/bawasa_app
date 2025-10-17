# Camera Functionality Implementation for Meter Readings

## Overview

This implementation adds mandatory photo capture functionality to the meter reading submission process. Users must now take a photo of their meter reading before they can submit it.

## Features Implemented

### 1. Camera Dependencies

- Added `camera: ^0.10.5+9` for camera access
- Added `image_picker: ^1.0.7` for photo selection
- Added `path_provider: ^2.1.2` for file management

### 2. Camera Service (`lib/services/camera_service.dart`)

- Singleton service for handling camera operations
- Methods for taking photos from camera or gallery
- Photo file management and storage
- Error handling for camera operations

### 3. Photo Upload Service (`lib/services/photo_upload_service.dart`)

- Handles photo upload to Supabase Storage
- Creates and manages storage buckets
- Generates public URLs for uploaded photos
- Photo deletion functionality

### 4. Database Schema Updates

- Added `photo_url` column to `meter_readings` table
- Updated entity, repository, and usecase layers
- Created migration script for existing databases

### 5. UI Updates (`lib/presentation/pages/meter_reading_page.dart`)

- Added photo capture section to the form
- Photo preview functionality
- Photo options modal (camera/gallery/remove)
- Form validation requiring photo before submission
- Visual feedback for photo status

## Key Components

### MeterReading Entity

- Added `photoUrl` field to store photo URL
- Updated JSON serialization/deserialization
- Updated copyWith and equality methods

### Repository Layer

- Added `submitMeterReadingWithPhoto` method
- Integrated photo upload service
- Handles photo upload before database insertion

### BLoC Layer

- Updated `SubmitMeterReading` event to include photo file
- Added `SubmitMeterReadingWithPhotoUseCase`
- Handles both photo and non-photo submissions

### UI Components

- Photo capture area with visual feedback
- Modal bottom sheet for photo options
- Photo preview with remove option
- Submit button state management based on photo presence

## Database Migration

### For New Installations

Use the updated `supabase_meter_readings_table.sql` which includes the `photo_url` column.

### For Existing Installations

Run the migration script `add_photo_url_migration.sql` to add the photo_url column to existing tables.

## Storage Setup

### Supabase Storage Bucket

The system automatically creates a `meter-readings` storage bucket with:

- Public access enabled
- File size limit: 5MB
- Allowed MIME types: image/jpeg, image/png, image/webp

### File Naming Convention

Photos are stored with the naming pattern:
`meter_reading_{user_id}_{timestamp}.jpg`

## User Experience

### Photo Capture Flow

1. User taps on the photo capture area
2. Modal appears with options: Take Photo, Choose from Gallery, Remove Photo
3. User selects an option
4. Photo is captured/selected and displayed in the form
5. Submit button becomes enabled only when photo is present

### Validation

- Photo is mandatory for submission
- Clear error messages guide users
- Visual feedback shows photo status
- Submit button text changes based on requirements

## Error Handling

- Camera permission errors
- Photo upload failures
- Network connectivity issues
- Storage quota exceeded
- Invalid file formats

## Security Considerations

- Photos are stored in Supabase Storage with proper access controls
- File size limits prevent abuse
- MIME type validation ensures only images are uploaded
- User can only access their own photos through RLS policies

## Future Enhancements

- Photo compression before upload
- Multiple photo support
- Photo editing capabilities
- Offline photo storage with sync
- Photo quality validation
- GPS location tagging for verification

## Testing Recommendations

1. Test camera permissions on different devices
2. Test photo upload with various network conditions
3. Test form validation with and without photos
4. Test photo deletion and replacement
5. Test error scenarios (camera unavailable, upload failure)
6. Test on different screen sizes and orientations
