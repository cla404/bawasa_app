import '../../domain/entities/meter_reading.dart';
import '../../domain/repositories/meter_reading_repository.dart';
import '../../services/supabase_config.dart';
import '../../services/photo_upload_service.dart';
import '../../core/error/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class MeterReadingRepositoryImpl implements MeterReadingRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final PhotoUploadService _photoUploadService = PhotoUploadService();

  @override
  Future<List<MeterReading>> getUserMeterReadings() async {
    try {
      print('🔍 [MeterReadingRepository] Fetching user meter readings...');
      print(
        '🔍 [MeterReadingRepository] Current user: ${_supabase.auth.currentUser?.id}',
      );

      // Check if user is authenticated
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw ServerFailure('User not authenticated. Please sign in first.');
      }

      // Get the user profile ID from the users table
      final userProfileResponse = await _supabase
          .from('users')
          .select('id')
          .eq('auth_user_id', currentUser.id)
          .maybeSingle();

      if (userProfileResponse == null) {
        throw ServerFailure(
          'User profile not found. Please complete your profile setup.',
        );
      }

      final userProfileId = userProfileResponse['id'] as String;
      print('🔍 [MeterReadingRepository] User profile ID: $userProfileId');

      final response = await _supabase
          .from('meter_readings')
          .select()
          .eq('user_id_ref', userProfileId) // Filter by current user
          .order('reading_date', ascending: false);

      print(
        '✅ [MeterReadingRepository] Successfully fetched ${(response as List).length} meter readings',
      );
      print('📊 [MeterReadingRepository] Response data: $response');

      return (response as List)
          .map((json) => MeterReading.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ [MeterReadingRepository] Error fetching meter readings: $e');
      print('❌ [MeterReadingRepository] Error type: ${e.runtimeType}');
      print('❌ [MeterReadingRepository] Error details: ${e.toString()}');
      throw ServerFailure('Failed to fetch meter readings: ${e.toString()}');
    }
  }

  @override
  Future<List<MeterReading>> getMeterReadingsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Check if user is authenticated
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw ServerFailure('User not authenticated. Please sign in first.');
      }

      // Get the user profile ID from the users table
      final userProfileResponse = await _supabase
          .from('users')
          .select('id')
          .eq('auth_user_id', currentUser.id)
          .maybeSingle();

      if (userProfileResponse == null) {
        throw ServerFailure(
          'User profile not found. Please complete your profile setup.',
        );
      }

      final userProfileId = userProfileResponse['id'] as String;

      final response = await _supabase
          .from('meter_readings')
          .select()
          .eq('user_id_ref', userProfileId) // Filter by current user
          .gte('reading_date', startDate.toIso8601String().split('T')[0])
          .lte('reading_date', endDate.toIso8601String().split('T')[0])
          .order('reading_date', ascending: false);

      return (response as List)
          .map((json) => MeterReading.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerFailure(
        'Failed to fetch meter readings by date range: ${e.toString()}',
      );
    }
  }

  /// Submit meter reading with photo upload
  Future<MeterReading> submitMeterReadingWithPhoto(
    MeterReading reading,
    File? photoFile,
  ) async {
    try {
      print(
        '📝 [MeterReadingRepository] Submitting meter reading with photo...',
      );

      String? photoUrl;

      // Upload photo if provided
      if (photoFile != null) {
        print('📸 [MeterReadingRepository] Uploading photo...');
        await _photoUploadService.ensureStorageBucketExists();
        photoUrl = await _photoUploadService.uploadPhoto(photoFile);

        // Update reading with photo URL
        reading = reading.copyWith(photoUrl: photoUrl);
      }

      return await submitMeterReading(reading);
    } catch (e) {
      print(
        '❌ [MeterReadingRepository] Error submitting meter reading with photo: $e',
      );
      throw ServerFailure(
        'Failed to submit meter reading with photo: ${e.toString()}',
      );
    }
  }

  @override
  Future<MeterReading> submitMeterReading(MeterReading reading) async {
    try {
      print('📝 [MeterReadingRepository] Submitting meter reading...');
      print(
        '📝 [MeterReadingRepository] Reading data: ${reading.toInsertJson()}',
      );
      print(
        '📝 [MeterReadingRepository] Current user: ${_supabase.auth.currentUser?.id}',
      );
      print(
        '📝 [MeterReadingRepository] User authenticated: ${_supabase.auth.currentUser != null}',
      );

      // Check if user is authenticated
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw ServerFailure('User not authenticated. Please sign in first.');
      }

      // Get the user profile ID from the users table
      final userProfileResponse = await _supabase
          .from('users')
          .select('id')
          .eq('auth_user_id', currentUser.id)
          .maybeSingle();

      if (userProfileResponse == null) {
        throw ServerFailure(
          'User profile not found. Please complete your profile setup.',
        );
      }

      final userProfileId = userProfileResponse['id'] as String;
      print('📝 [MeterReadingRepository] User profile ID: $userProfileId');

      final insertData = reading.toInsertJson();
      // Add both user_id_ref and user_id during transition period
      insertData['user_id_ref'] = userProfileId;
      insertData['user_id'] = currentUser.id; // Keep old column for transition
      print('📝 [MeterReadingRepository] Insert data: $insertData');

      final response = await _supabase
          .from('meter_readings')
          .insert(insertData)
          .select()
          .single();

      print('✅ [MeterReadingRepository] Successfully submitted meter reading');
      print('📊 [MeterReadingRepository] Response: $response');

      return MeterReading.fromJson(response);
    } catch (e) {
      print('❌ [MeterReadingRepository] Error submitting meter reading: $e');
      print('❌ [MeterReadingRepository] Error type: ${e.runtimeType}');
      print('❌ [MeterReadingRepository] Error details: ${e.toString()}');

      // Check if it's a Supabase-specific error
      if (e is PostgrestException) {
        print('❌ [MeterReadingRepository] PostgrestException details:');
        print('   - Code: ${e.code}');
        print('   - Message: ${e.message}');
        print('   - Details: ${e.details}');
        print('   - Hint: ${e.hint}');
      }

      throw ServerFailure('Failed to submit meter reading: ${e.toString()}');
    }
  }

  @override
  Future<MeterReading> updateMeterReading(MeterReading reading) async {
    try {
      final response = await _supabase
          .from('meter_readings')
          .update(reading.toJson())
          .eq('id', reading.id)
          .eq('status', 'pending') // Only allow updates to pending readings
          .select()
          .single();

      return MeterReading.fromJson(response);
    } catch (e) {
      throw ServerFailure('Failed to update meter reading: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteMeterReading(String readingId) async {
    try {
      await _supabase
          .from('meter_readings')
          .delete()
          .eq('id', readingId)
          .eq('status', 'pending'); // Only allow deletion of pending readings
    } catch (e) {
      throw ServerFailure('Failed to delete meter reading: ${e.toString()}');
    }
  }

  @override
  Future<MeterReading?> getLatestMeterReading() async {
    try {
      print('🔍 [MeterReadingRepository] Fetching latest meter reading...');
      print(
        '🔍 [MeterReadingRepository] Current user: ${_supabase.auth.currentUser?.id}',
      );

      // Check if user is authenticated
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw ServerFailure('User not authenticated. Please sign in first.');
      }

      // Get the user profile ID from the users table
      final userProfileResponse = await _supabase
          .from('users')
          .select('id')
          .eq('auth_user_id', currentUser.id)
          .maybeSingle();

      if (userProfileResponse == null) {
        throw ServerFailure(
          'User profile not found. Please complete your profile setup.',
        );
      }

      final userProfileId = userProfileResponse['id'] as String;
      print('🔍 [MeterReadingRepository] User profile ID: $userProfileId');

      final response = await _supabase
          .from('meter_readings')
          .select()
          .eq('user_id_ref', userProfileId) // Filter by current user
          .order('reading_date', ascending: false)
          .limit(1);

      print('📊 [MeterReadingRepository] Latest reading response: $response');

      if (response.isEmpty) {
        print('ℹ️ [MeterReadingRepository] No meter readings found');
        return null;
      }

      print('✅ [MeterReadingRepository] Found latest meter reading');
      return MeterReading.fromJson(response.first);
    } catch (e) {
      print(
        '❌ [MeterReadingRepository] Error fetching latest meter reading: $e',
      );
      print('❌ [MeterReadingRepository] Error type: ${e.runtimeType}');
      print('❌ [MeterReadingRepository] Error details: ${e.toString()}');

      if (e is PostgrestException) {
        print('❌ [MeterReadingRepository] PostgrestException details:');
        print('   - Code: ${e.code}');
        print('   - Message: ${e.message}');
        print('   - Details: ${e.details}');
        print('   - Hint: ${e.hint}');
      }

      throw ServerFailure(
        'Failed to fetch latest meter reading: ${e.toString()}',
      );
    }
  }

  @override
  Future<MeterReading?> getMeterReadingById(String readingId) async {
    try {
      final response = await _supabase
          .from('meter_readings')
          .select()
          .eq('id', readingId)
          .single();

      return MeterReading.fromJson(response);
    } catch (e) {
      if (e.toString().contains('No rows returned')) {
        return null;
      }
      throw ServerFailure(
        'Failed to fetch meter reading by ID: ${e.toString()}',
      );
    }
  }
}
