import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_config.dart';
import '../../core/error/failures.dart';

class PhotoUploadService {
  static final PhotoUploadService _instance = PhotoUploadService._internal();
  factory PhotoUploadService() => _instance;
  PhotoUploadService._internal();

  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Upload photo to Supabase Storage
  Future<String> uploadPhoto(File photoFile) async {
    try {
      print('📸 [PhotoUploadService] Starting photo upload...');

      // Check if user is authenticated
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw ServerFailure('User not authenticated. Please sign in first.');
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'meter_reading_${currentUser.id}_$timestamp.jpg';
      final filePath = 'meter-readings/$fileName';

      print('📸 [PhotoUploadService] Uploading to path: $filePath');

      // Upload file to Supabase Storage
      await _supabase.storage
          .from('meter-readings')
          .upload(filePath, photoFile);

      // Get public URL
      final publicUrl = _supabase.storage
          .from('meter-readings')
          .getPublicUrl(filePath);

      print('✅ [PhotoUploadService] Photo uploaded successfully');
      print('📸 [PhotoUploadService] Public URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('❌ [PhotoUploadService] Error uploading photo: $e');
      print('❌ [PhotoUploadService] Error type: ${e.runtimeType}');
      throw ServerFailure('Failed to upload photo: ${e.toString()}');
    }
  }

  /// Delete photo from Supabase Storage
  Future<void> deletePhoto(String photoUrl) async {
    try {
      print('🗑️ [PhotoUploadService] Deleting photo: $photoUrl');

      // Extract file path from URL
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;

      // Find the bucket and file path
      final bucketIndex = pathSegments.indexOf('meter-readings');
      if (bucketIndex == -1 || bucketIndex + 1 >= pathSegments.length) {
        throw ServerFailure('Invalid photo URL format');
      }

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      print('🗑️ [PhotoUploadService] Deleting file path: $filePath');

      await _supabase.storage.from('meter-readings').remove([filePath]);

      print('✅ [PhotoUploadService] Photo deleted successfully');
    } catch (e) {
      print('❌ [PhotoUploadService] Error deleting photo: $e');
      print('❌ [PhotoUploadService] Error type: ${e.runtimeType}');
      throw ServerFailure('Failed to delete photo: ${e.toString()}');
    }
  }

  /// Check if storage bucket exists and create if needed
  Future<void> ensureStorageBucketExists() async {
    try {
      print('🔍 [PhotoUploadService] Checking storage bucket...');

      final buckets = await _supabase.storage.listBuckets();
      final bucketExists = buckets.any(
        (bucket) => bucket.name == 'meter-readings',
      );

      if (!bucketExists) {
        print('📦 [PhotoUploadService] Creating storage bucket...');
        await _supabase.storage.createBucket(
          'meter-readings',
          BucketOptions(
            public: true,
            allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
            fileSizeLimit: '5MB', // 5MB limit
          ),
        );
        print('✅ [PhotoUploadService] Storage bucket created successfully');
      } else {
        print('✅ [PhotoUploadService] Storage bucket already exists');
      }
    } catch (e) {
      print('❌ [PhotoUploadService] Error ensuring storage bucket: $e');
      print('❌ [PhotoUploadService] Error type: ${e.runtimeType}');
      throw ServerFailure('Failed to ensure storage bucket: ${e.toString()}');
    }
  }
}
