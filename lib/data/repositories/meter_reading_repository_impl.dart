import '../../domain/entities/meter_reading.dart';
import '../../domain/entities/meter_reading_submission.dart';
import '../../domain/entities/consumer.dart';
import '../../domain/repositories/meter_reading_repository.dart';
import '../../services/supabase_config.dart';
import '../../services/photo_upload_service.dart';
import '../../core/error/failures.dart';
import '../../core/utils/bawasa_billing_calculator.dart';
import '../../data/repositories/supabase_accounts_auth_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_it/get_it.dart';
import 'dart:io';

class MeterReadingRepositoryImpl implements MeterReadingRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final PhotoUploadService _photoUploadService = PhotoUploadService();

  @override
  Future<List<MeterReading>> getUserMeterReadings() async {
    try {
      print('🔍 [MeterReadingRepository] Fetching user meter readings...');

      // Get current user from Supabase accounts auth
      final supabaseAccountsAuthRepo =
          GetIt.instance<SupabaseAccountsAuthRepositoryImpl>();
      final currentUser = supabaseAccountsAuthRepo.getCurrentUser();

      if (currentUser == null) {
        throw ServerFailure('User not authenticated. Please sign in first.');
      }

      print('🔍 [MeterReadingRepository] Current user: ${currentUser.email}');

      // Get the consumer meter readings from bawasa_meter_readings table
      // First, get the consumer ID from consumers table
      final consumerResponse = await _supabase
          .from('consumers')
          .select('id')
          .eq('consumer_id', currentUser.id)
          .maybeSingle();

      if (consumerResponse == null) {
        print(
          '❌ [MeterReadingRepository] Consumer not found for user: ${currentUser.id}',
        );
        return [];
      }

      final consumerId = consumerResponse['id'] as String;
      print('🔍 [MeterReadingRepository] Found consumer ID: $consumerId');

      // Now get meter readings for this consumer
      final response = await _supabase
          .from('bawasa_meter_readings')
          .select('*')
          .eq('consumer_id', consumerId)
          .order('created_at', ascending: false);

      print(
        '✅ [MeterReadingRepository] Successfully fetched ${(response as List).length} meter readings',
      );
      print('📊 [MeterReadingRepository] Response data: $response');

      // Convert bawasa_meter_readings records to MeterReading entities
      return (response as List)
          .map((json) => _convertMeterReadingToEntity(json))
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
      // Get current user from Supabase accounts auth
      final supabaseAccountsAuthRepo =
          GetIt.instance<SupabaseAccountsAuthRepositoryImpl>();
      final currentUser = supabaseAccountsAuthRepo.getCurrentUser();

      if (currentUser == null) {
        throw ServerFailure('User not authenticated. Please sign in first.');
      }

      // First, get the consumer ID from consumers table
      final consumerResponse = await _supabase
          .from('consumers')
          .select('id')
          .eq('consumer_id', currentUser.id)
          .maybeSingle();

      if (consumerResponse == null) {
        print(
          '❌ [MeterReadingRepository] Consumer not found for user: ${currentUser.id}',
        );
        return [];
      }

      final consumerId = consumerResponse['id'] as String;

      final response = await _supabase
          .from('bawasa_meter_readings')
          .select('*')
          .eq('consumer_id', consumerId)
          .gte('created_at', startDate.toIso8601String().split('T')[0])
          .lte('created_at', endDate.toIso8601String().split('T')[0])
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => _convertMeterReadingToEntity(json))
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

      // Upload photo if provided - use user_id_ref as consumer identifier
      if (photoFile != null && reading.user_id_ref.isNotEmpty) {
        print('📸 [MeterReadingRepository] Uploading photo...');
        await _photoUploadService.ensureStorageBucketExists();
        photoUrl = await _photoUploadService.uploadPhoto(
          photoFile,
          consumerId: reading.user_id_ref,
        );

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

      // Get current user from Supabase accounts auth
      final supabaseAccountsAuthRepo =
          GetIt.instance<SupabaseAccountsAuthRepositoryImpl>();
      final currentUser = supabaseAccountsAuthRepo.getCurrentUser();

      if (currentUser == null) {
        throw ServerFailure('User not authenticated. Please sign in first.');
      }

      print('🔍 [MeterReadingRepository] Current user: ${currentUser.email}');

      // First, get the consumer ID from consumers table
      final consumerResponse = await _supabase
          .from('consumers')
          .select('id')
          .eq('consumer_id', currentUser.id)
          .maybeSingle();

      if (consumerResponse == null) {
        print(
          '❌ [MeterReadingRepository] Consumer not found for user: ${currentUser.id}',
        );
        return null;
      }

      final consumerId = consumerResponse['id'] as String;

      // Get the latest meter reading from bawasa_meter_readings table
      final response = await _supabase
          .from('bawasa_meter_readings')
          .select('*')
          .eq('consumer_id', consumerId)
          .order('created_at', ascending: false)
          .limit(1);

      print('📊 [MeterReadingRepository] Latest reading response: $response');

      if (response.isEmpty) {
        print('ℹ️ [MeterReadingRepository] No meter readings found');
        return null;
      }

      print('✅ [MeterReadingRepository] Found latest meter reading');
      return _convertMeterReadingToEntity(response.first);
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

  // Meter Reader specific methods
  @override
  Future<MeterReadingSubmission> submitMeterReadingForConsumer(
    MeterReadingSubmission submission,
    File? meterImageFile,
  ) async {
    try {
      print(
        '📝 [MeterReadingRepository] Submitting meter reading for consumer...',
      );

      // Get current user for updating assignment status
      final supabaseAccountsAuthRepo =
          GetIt.instance<SupabaseAccountsAuthRepositoryImpl>();
      final currentUser = supabaseAccountsAuthRepo.getCurrentUser();
      final customUser = supabaseAccountsAuthRepo.getCurrentCustomUser();
      
      // Check if meter reader is suspended
      if (customUser != null && 
          customUser.userType == 'meter_reader' && 
          customUser.status?.toLowerCase() == 'suspended') {
        throw ServerFailure(
          'Your account has been suspended. You cannot submit new meter readings. Please contact the administrator for assistance.'
        );
      }

      String? meterImageUrl;

      // Upload meter image if provided
      if (meterImageFile != null && submission.consumerId != null) {
        print('📸 [MeterReadingRepository] Uploading meter image...');
        // Bucket already exists, no need to create it
        try {
          meterImageUrl = await _photoUploadService.uploadPhoto(
            meterImageFile,
            consumerId: submission.consumerId!,
          );
        } catch (e) {
          print(
            '⚠️ [MeterReadingRepository] Warning: Failed to upload image, continuing without image: $e',
          );
          // Continue without image if upload fails
        }
      }

      // Prepare data for insertion into bawasa_meter_readings table
      final insertData = {
        'consumer_id': submission.consumerId,
        'previous_reading': submission.previousReading,
        'present_reading': submission.presentReading,
        'remarks': submission.remarks,
        'reading_assigned': true, // Set reading_assigned to true
        'meter_image':
            meterImageUrl, // Store the image URL in meter_image column
        'created_at': submission.createdAt.toIso8601String(),
        'updated_at': submission.createdAt.toIso8601String(),
      };

      print('📝 [MeterReadingRepository] Insert data: $insertData');

      final response = await _supabase
          .from('bawasa_meter_readings')
          .insert(insertData)
          .select()
          .single();

      print(
        '✅ [MeterReadingRepository] Successfully submitted meter reading to bawasa_meter_readings',
      );
      print('📊 [MeterReadingRepository] Response: $response');

      // Get the meter reading ID and consumption
      final meterReadingId = response['id'] as String;
      final consumption = (response['consumption_cubic_meters'] as num)
          .toDouble();

      // Now create a billing record
      print('💰 [MeterReadingRepository] Creating billing record...');

      // Get consumer's account creation date to calculate years of service
      int yearsOfService = 0;
      try {
        if (submission.consumerId != null) {
          // Get the consumer record to find the account ID
          final consumerResponse = await _supabase
              .from('consumers')
              .select('consumer_id, created_at')
              .eq('id', submission.consumerId!)
              .single();

          DateTime? accountCreationDate;

          // Get account creation date from accounts table using consumer_id foreign key
          if (consumerResponse['consumer_id'] != null) {
            final accountId = consumerResponse['consumer_id'] as int;
            final accountResponse = await _supabase
                .from('accounts')
                .select('created_at')
                .eq('id', accountId)
                .maybeSingle();

            if (accountResponse != null &&
                accountResponse['created_at'] != null) {
              accountCreationDate = DateTime.parse(
                accountResponse['created_at'],
              );
            }
          }

          // If account creation date not found, use consumer creation date as fallback
          if (accountCreationDate == null &&
              consumerResponse['created_at'] != null) {
            accountCreationDate = DateTime.parse(
              consumerResponse['created_at'],
            );
          }

          // Calculate years of service
          if (accountCreationDate != null) {
            yearsOfService = BAWASABillingCalculator.calculateYearsOfService(
              accountCreationDate,
            );
            print(
              '📅 [MeterReadingRepository] Account created: $accountCreationDate',
            );
            print(
              '📅 [MeterReadingRepository] Years of service: $yearsOfService',
            );
            print(
              '📅 [MeterReadingRepository] Discount percentage: ${BAWASABillingCalculator.getDiscountPercentage(yearsOfService) * 100}%',
            );
          }
        }
      } catch (e) {
        print(
          '⚠️ [MeterReadingRepository] Warning: Could not calculate years of service: $e',
        );
        print('⚠️ [MeterReadingRepository] Stack trace: ${StackTrace.current}');
        // Continue with 0 years (no discount) if calculation fails
        yearsOfService = 0;
      }

      // Calculate billing using BAWASA calculator with years of service
      final billingCalc = BAWASABillingCalculator.calculateBilling(
        consumption,
        yearsOfService: yearsOfService,
      );

      // Calculate due date (30 days from now)
      final dueDate = DateTime.now().add(const Duration(days: 30));

      // Get billing month (current month name + year)
      final billingMonth =
          '${_getMonthName(DateTime.now().month)} ${DateTime.now().year}';

      // Prepare billing data
      final billingData = {
        'consumer_id': submission.consumerId,
        'meter_reading_id': meterReadingId,
        'billing_month': billingMonth,
        'consumption_10_or_below': billingCalc.consumption10OrBelow,
        'amount_10_or_below': billingCalc.amount10OrBelow,
        'amount_10_or_below_with_discount':
            billingCalc.amount10OrBelowWithDiscount,
        'consumption_over_10': billingCalc.consumptionOver10,
        'amount_over_10': billingCalc.amountOver10,
        'amount_current_billing': billingCalc.amountCurrentBilling,
        'arrears_to_be_paid': 0,
        'due_date': dueDate.toIso8601String().split('T')[0],
        'arrears_after_due_date': null,
        'payment_status': 'unpaid',
        'payment_date': null,
        'amount_paid': 0,
        'reading_assigned': true,
        'created_at': submission.createdAt.toIso8601String(),
        'updated_at': submission.createdAt.toIso8601String(),
      };

      print('📝 [MeterReadingRepository] Billing data: $billingData');

      final billingResponse = await _supabase
          .from('bawasa_billings')
          .insert(billingData)
          .select()
          .single();

      print('✅ [MeterReadingRepository] Successfully created billing record');
      print('📊 [MeterReadingRepository] Billing response: $billingResponse');

      // Update the assignment status to 'completed'
      print(
        '📝 [MeterReadingRepository] Updating assignment status to completed...',
      );

      try {
        if (currentUser != null) {
          // Get the meter reader's database ID from bawasa_meter_reader table
          final meterReaderResponse = await _supabase
              .from('bawasa_meter_reader')
              .select('id')
              .eq('reader_id', currentUser.id)
              .maybeSingle();

          if (meterReaderResponse != null) {
            final meterReaderId = meterReaderResponse['id'] as int;

            if (submission.consumerId != null) {
              // Update the assignment status to 'completed'
              await _supabase
                  .from('meter_reader_assignments')
                  .update({
                    'status': 'completed',
                    'updated_at': DateTime.now().toIso8601String(),
                  })
                  .eq('meter_reader_id', meterReaderId)
                  .eq('consumer_id', submission.consumerId!)
                  .eq('status', 'assigned');

              print(
                '✅ [MeterReadingRepository] Assignment status updated to completed',
              );
            }
          }
        }
      } catch (e) {
        print(
          '⚠️ [MeterReadingRepository] Warning: Failed to update assignment status: $e',
        );
        // Continue anyway, don't fail the entire operation
      }

      // Convert response to MeterReadingSubmission format
      // Note: The response will contain the auto-generated consumption_cubic_meters
      return MeterReadingSubmission(
        id: meterReadingId,
        previousReading: response['previous_reading'] as double,
        presentReading: response['present_reading'] as double,
        numberOfConsumption: consumption.toInt(),
        remarks: response['remarks'] as String?,
        consumerId: response['consumer_id'] as String,
        meterImage: meterImageUrl,
        createdAt: DateTime.parse(response['created_at'] as String),
      );
    } catch (e) {
      print(
        '❌ [MeterReadingRepository] Error submitting meter reading for consumer: $e',
      );
      throw ServerFailure(
        'Failed to submit meter reading for consumer: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<Consumer>> getConsumersForMeterReader() async {
    try {
      print(
        '🔍 [MeterReadingRepository] Fetching consumers for meter reader...',
      );

      // Get current user from Supabase accounts auth
      final supabaseAccountsAuthRepo =
          GetIt.instance<SupabaseAccountsAuthRepositoryImpl>();
      final currentUser = supabaseAccountsAuthRepo.getCurrentUser();

      if (currentUser == null) {
        throw ServerFailure('User not authenticated. Please sign in first.');
      }

      print('🔍 [MeterReadingRepository] Current user: ${currentUser.email}');

      // First, get the meter reader's database ID from bawasa_meter_reader table
      final meterReaderResponse = await _supabase
          .from('bawasa_meter_reader')
          .select('id')
          .eq('reader_id', currentUser.id)
          .maybeSingle();

      if (meterReaderResponse == null) {
        print('❌ [MeterReadingRepository] Meter reader not found in database');
        throw ServerFailure('Meter reader data not found');
      }

      final meterReaderId = meterReaderResponse['id'] as int;
      print('🔍 [MeterReadingRepository] Meter reader ID: $meterReaderId');

      // Now fetch consumers assigned to this meter reader from meter_reader_assignments
      final assignmentsResponse = await _supabase
          .from('meter_reader_assignments')
          .select('''
            *,
            consumers!consumer_id (
              *,
              accounts!consumer_id (
                *
              )
            )
          ''')
          .eq('meter_reader_id', meterReaderId)
          .eq('status', 'assigned')
          .order('created_at', ascending: true);

      print(
        '✅ [MeterReadingRepository] Successfully fetched ${(assignmentsResponse as List).length} assigned consumers',
      );

      // Get current month boundaries
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Filter consumers who don't have readings for the current month
      final availableConsumers = <Map<String, dynamic>>[];

      for (final assignment in (assignmentsResponse as List)) {
        final consumerData = assignment['consumers'] as Map<String, dynamic>;
        final consumerId = consumerData['id'] as String;

        // Check if consumer already has a reading for current month
        final readingsResponse = await _supabase
            .from('bawasa_meter_readings')
            .select('id')
            .eq('consumer_id', consumerId)
            .gte('created_at', startOfMonth.toIso8601String())
            .lte('created_at', endOfMonth.toIso8601String())
            .maybeSingle();

        // Only include consumers who don't have readings for this month
        if (readingsResponse == null) {
          availableConsumers.add(assignment);
        } else {
          print(
            'ℹ️ [MeterReadingRepository] Consumer $consumerId already has reading for this month, skipping',
          );
        }
      }

      print(
        '✅ [MeterReadingRepository] Found ${availableConsumers.length} consumers needing readings',
      );

      // Convert the assigned consumers to Consumer entities
      return availableConsumers.map((assignment) {
        final consumerData = assignment['consumers'] as Map<String, dynamic>;
        final accountData = consumerData['accounts'] as Map<String, dynamic>?;

        return Consumer(
          id: consumerData['id'] as String,
          waterMeterNo: consumerData['water_meter_no'] ?? '',
          fullName: accountData?['full_name'] ?? '',
          fullAddress: accountData?['full_address'] ?? '',
          phone: accountData?['mobile_no']?.toString() ?? '',
          email: accountData?['email'] ?? '',
          previousReading: 0.0,
          currentReading: 0.0,
          consumptionCubicMeters: 0.0,
          amountCurrentBilling: 0.0,
          billingMonth: '',
          meterReadingDate: '',
          dueDate: '',
          status: '',
          createdAt: DateTime.parse(consumerData['created_at'] as String),
          updatedAt: DateTime.parse(consumerData['updated_at'] as String),
        );
      }).toList();
    } catch (e) {
      print('❌ [MeterReadingRepository] Error fetching consumers: $e');
      throw ServerFailure('Failed to fetch consumers: ${e.toString()}');
    }
  }

  @override
  Future<Consumer?> getConsumerById(String consumerId) async {
    try {
      print('🔍 [MeterReadingRepository] Fetching consumer by ID: $consumerId');

      final response = await _supabase
          .from('consumers')
          .select('*')
          .eq('id', consumerId)
          .maybeSingle();

      if (response == null) {
        print('ℹ️ [MeterReadingRepository] Consumer not found');
        return null;
      }

      print('✅ [MeterReadingRepository] Successfully fetched consumer');
      return _convertConsumerData(response);
    } catch (e) {
      print('❌ [MeterReadingRepository] Error fetching consumer by ID: $e');
      throw ServerFailure('Failed to fetch consumer by ID: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCompletedMeterReadings() async {
    try {
      print('🔍 [MeterReadingRepository] Fetching completed meter readings...');

      // Get current user
      final supabaseAccountsAuthRepo =
          GetIt.instance<SupabaseAccountsAuthRepositoryImpl>();
      final currentUser = supabaseAccountsAuthRepo.getCurrentUser();

      if (currentUser == null) {
        throw ServerFailure('User not authenticated');
      }

      // Get the meter reader's database ID
      final meterReaderResponse = await _supabase
          .from('bawasa_meter_reader')
          .select('id')
          .eq('reader_id', currentUser.id)
          .maybeSingle();

      if (meterReaderResponse == null) {
        print('❌ [MeterReadingRepository] Meter reader not found');
        return [];
      }

      final meterReaderId = meterReaderResponse['id'] as int;

      // Fetch completed assignments with consumer and account info
      final assignmentsResponse = await _supabase
          .from('meter_reader_assignments')
          .select('''
            *,
            consumers!consumer_id (
              *,
              accounts!consumer_id (
                *
              )
            )
          ''')
          .eq('meter_reader_id', meterReaderId)
          .eq('status', 'completed')
          .order('updated_at', ascending: false);

      // Fetch meter readings for each completed assignment
      final results = <Map<String, dynamic>>[];

      for (final assignment in (assignmentsResponse as List)) {
        final consumer = assignment['consumers'] as Map<String, dynamic>;
        final consumerId = consumer['id'] as String;

        // Get meter readings for this consumer
        final readingsResponse = await _supabase
            .from('bawasa_meter_readings')
            .select('*')
            .eq('consumer_id', consumerId)
            .order('created_at', ascending: false)
            .limit(1); // Get the latest reading

        assignment['bawasa_meter_readings'] = readingsResponse;
        results.add(assignment);
      }

      print(
        '✅ [MeterReadingRepository] Successfully fetched ${results.length} completed readings',
      );

      return results;
    } catch (e) {
      print('❌ [MeterReadingRepository] Error fetching completed readings: $e');
      throw ServerFailure(
        'Failed to fetch completed readings: ${e.toString()}',
      );
    }
  }

  /// Helper method to convert bawasa_meter_readings record to MeterReading entity
  MeterReading _convertMeterReadingToEntity(
    Map<String, dynamic> meterReadingData,
  ) {
    final createdAt = DateTime.parse(meterReadingData['created_at'] as String);
    final updatedAt = meterReadingData['updated_at'] != null
        ? DateTime.parse(meterReadingData['updated_at'] as String)
        : createdAt;

    return MeterReading(
      id: meterReadingData['id'] as String,
      user_id_ref: meterReadingData['consumer_id'].toString(),
      meterType: 'Water',
      readingValue: (meterReadingData['present_reading'] as num).toDouble(),
      readingDate: createdAt,
      notes: meterReadingData['remarks'] as String?,
      photoUrl: meterReadingData['meter_image'] as String?,
      status: 'confirmed', // Meter readings are confirmed
      createdAt: createdAt,
      updatedAt: updatedAt,
      confirmedBy: 'system',
      confirmedAt: createdAt,
      consumption:
          (meterReadingData['consumption_cubic_meters'] as num?)?.toDouble() ??
          0.0,
    );
  }

  /// Helper method to convert consumer data to Consumer entity
  Consumer _convertConsumerData(Map<String, dynamic> consumerData) {
    return Consumer(
      id: consumerData['id'] as String,
      waterMeterNo: consumerData['water_meter_no'] ?? '',
      fullName: '', // Will need to fetch from accounts table separately
      fullAddress: '', // Will need to fetch from accounts table separately
      phone: '', // Will need to fetch from accounts table separately
      email: '', // Will need to fetch from accounts table separately
      previousReading:
          0.0, // Default values since we don't have meter reading data here
      currentReading: 0.0,
      consumptionCubicMeters: 0.0,
      amountCurrentBilling: 0.0,
      billingMonth: '',
      meterReadingDate: '',
      dueDate: '',
      status: '',
      createdAt: DateTime.parse(consumerData['created_at'] as String),
      updatedAt: DateTime.parse(consumerData['updated_at'] as String),
    );
  }

  /// Helper method to get month name from month number
  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
