import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_config.dart';
import '../../core/error/failures.dart';
import '../../core/injection/injection_container.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/consumer_repository.dart';

class PhotoUploadService {
  static final PhotoUploadService _instance = PhotoUploadService._internal();
  factory PhotoUploadService() => _instance;
  PhotoUploadService._internal();

  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Upload photo to Supabase Storage
  Future<String> uploadPhoto(File photoFile) async {
    try {
      print('📸 [PhotoUploadService] Starting photo upload...');

      // Check if user is authenticated using custom auth system
      final authRepository = sl<AuthRepository>();
      final currentUser = authRepository.getCurrentUser();
      if (currentUser == null) {
        throw ServerFailure('User not authenticated. Please sign in first.');
      }

      // Generate unique filename using custom user ID
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

  /// Upload issue report photo to Supabase Storage with consumer ID folder structure
  Future<String> uploadIssuePhoto(File photoFile) async {
    try {
      print('📸 [PhotoUploadService] Starting issue photo upload...');

      // Check if user is authenticated using custom auth system
      final authRepository = sl<AuthRepository>();
      final currentUser = authRepository.getCurrentUser();
      if (currentUser == null) {
        throw ServerFailure('User not authenticated. Please sign in first.');
      }

      // Get the consumer ID from the accounts table using the user ID
      final consumerRepository = sl<ConsumerRepository>();
      final consumer = await consumerRepository.getConsumerByUserId(
        currentUser.id,
      );

      if (consumer == null) {
        throw ServerFailure(
          'Consumer profile not found. Please complete your consumer registration.',
        );
      }

      return await _uploadIssuePhotoWithConsumerId(photoFile, consumer.id);
    } catch (e) {
      print('❌ [PhotoUploadService] Error uploading issue photo: $e');
      print('❌ [PhotoUploadService] Error type: ${e.runtimeType}');
      throw ServerFailure('Failed to upload issue photo: ${e.toString()}');
    }
  }

  /// Upload issue report photo with pre-obtained consumer ID (optimized for batch uploads)
  Future<String> uploadIssuePhotoWithConsumerId(
    File photoFile,
    String consumerId,
  ) async {
    try {
      print('📸 [PhotoUploadService] Starting optimized issue photo upload...');
      return await _uploadIssuePhotoWithConsumerId(photoFile, consumerId);
    } catch (e) {
      print('❌ [PhotoUploadService] Error uploading issue photo: $e');
      print('❌ [PhotoUploadService] Error type: ${e.runtimeType}');
      throw ServerFailure('Failed to upload issue photo: ${e.toString()}');
    }
  }

  /// Internal method to upload issue photo with consumer ID
  Future<String> _uploadIssuePhotoWithConsumerId(
    File photoFile,
    String consumerId,
  ) async {
    // Generate unique filename using timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'issue_report_$timestamp.jpg';

    // Create folder structure: issue report/consumer_{consumer_id}/filename
    final filePath = 'issue report/consumer_$consumerId/$fileName';

    print('📸 [PhotoUploadService] Uploading to path: $filePath');
    print('📸 [PhotoUploadService] Consumer ID: $consumerId');

    // Upload file to Supabase Storage
    await _supabase.storage.from('issue report').upload(filePath, photoFile);

    // Get public URL
    final publicUrl = _supabase.storage
        .from('issue report')
        .getPublicUrl(filePath);

    print('✅ [PhotoUploadService] Issue photo uploaded successfully');
    print('📸 [PhotoUploadService] Public URL: $publicUrl');

    return publicUrl;
  }

  /// Delete photo from Supabase Storage
  Future<void> deletePhoto(String photoUrl) async {
    try {
      print('🗑️ [PhotoUploadService] Deleting photo: $photoUrl');

      // Extract file path from URL
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;

      // Find the bucket and file path
      String bucketName;
      int bucketIndex = pathSegments.indexOf('meter-readings');
      if (bucketIndex != -1) {
        bucketName = 'meter-readings';
      } else {
        bucketIndex = pathSegments.indexOf('issue%20report');
        if (bucketIndex != -1) {
          bucketName = 'issue report';
        } else {
          throw ServerFailure('Invalid photo URL format - bucket not found');
        }
      }

      if (bucketIndex + 1 >= pathSegments.length) {
        throw ServerFailure('Invalid photo URL format');
      }

      // For issue report URLs, handle the consumer folder structure
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      print(
        '🗑️ [PhotoUploadService] Deleting file path: $filePath from bucket: $bucketName',
      );

      await _supabase.storage.from(bucketName).remove([filePath]);

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
      print('🔍 [PhotoUploadService] Checking storage buckets...');

      final buckets = await _supabase.storage.listBuckets();

      // Check for meter-readings bucket
      final meterReadingsExists = buckets.any(
        (bucket) => bucket.name == 'meter-readings',
      );

      if (!meterReadingsExists) {
        print('📦 [PhotoUploadService] Creating meter-readings bucket...');
        await _supabase.storage.createBucket(
          'meter-readings',
          BucketOptions(
            public: true,
            allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
            fileSizeLimit: '5MB', // 5MB limit
          ),
        );
        print(
          '✅ [PhotoUploadService] meter-readings bucket created successfully',
        );
      } else {
        print('✅ [PhotoUploadService] meter-readings bucket already exists');
      }

      // Check for issue report bucket
      final issueReportExists = buckets.any(
        (bucket) => bucket.name == 'issue report',
      );

      if (!issueReportExists) {
        print('📦 [PhotoUploadService] Creating issue report bucket...');
        await _supabase.storage.createBucket(
          'issue report',
          BucketOptions(
            public: true,
            allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
            fileSizeLimit: '5MB', // 5MB limit
          ),
        );
        print(
          '✅ [PhotoUploadService] issue report bucket created successfully',
        );
      } else {
        print('✅ [PhotoUploadService] issue report bucket already exists');
      }
    } catch (e) {
      print('❌ [PhotoUploadService] Error ensuring storage buckets: $e');
      print('❌ [PhotoUploadService] Error type: ${e.runtimeType}');
      throw ServerFailure('Failed to ensure storage buckets: ${e.toString()}');
    }
  }
}
