import '../../domain/entities/consumer.dart';
import '../../domain/repositories/consumer_repository.dart';
import '../../core/config/supabase_config.dart';
import '../../core/error/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsumerRepositoryImpl implements ConsumerRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  @override
  Future<Consumer?> getConsumerDetails(String consumerId) async {
    try {
      print(
        '🔍 [ConsumerRepository] Fetching consumer details for ID: $consumerId',
      );

      // Get consumer data from consumers table
      final consumerResponse = await _supabase
          .from('consumers')
          .select('*')
          .eq('id', consumerId)
          .maybeSingle();

      if (consumerResponse == null) {
        print(
          'ℹ️ [ConsumerRepository] Consumer not found with ID: $consumerId',
        );
        return null;
      }

      // Get account data from accounts table using consumer_id foreign key
      final accountResponse = await _supabase
          .from('accounts')
          .select('full_name, full_address, mobile_no, email')
          .eq('id', consumerResponse['consumer_id'])
          .maybeSingle();

      if (accountResponse == null) {
        print(
          'ℹ️ [ConsumerRepository] Account not found for consumer: $consumerId',
        );
        return null;
      }

      print('✅ [ConsumerRepository] Successfully fetched consumer details');
      print('📊 [ConsumerRepository] Consumer data: $consumerResponse');
      print('📊 [ConsumerRepository] Account data: $accountResponse');

      // Merge the data from both tables
      final mergedData = {
        ...consumerResponse,
        'full_name': accountResponse['full_name'] ?? '',
        'full_address': accountResponse['full_address'] ?? '',
        'mobile_no': accountResponse['mobile_no'] ?? '',
        'email': accountResponse['email'] ?? '',
      };

      return Consumer.fromJson(mergedData);
    } catch (e) {
      print('❌ [ConsumerRepository] Error fetching consumer details: $e');
      print('❌ [ConsumerRepository] Error type: ${e.runtimeType}');

      if (e is PostgrestException && e.code == 'PGRST116') {
        print('ℹ️ [ConsumerRepository] Consumer not found');
        return null;
      }

      throw ServerFailure('Failed to fetch consumer details: ${e.toString()}');
    }
  }

  @override
  Future<Consumer?> getConsumerByUserId(String userId) async {
    try {
      print('🔍 [ConsumerRepository] Fetching consumer by user ID: $userId');

      // Get consumer data from consumers table using consumer_id foreign key
      final consumerResponse = await _supabase
          .from('consumers')
          .select('*')
          .eq('consumer_id', userId)
          .maybeSingle();

      if (consumerResponse == null) {
        print('ℹ️ [ConsumerRepository] No consumer found for user: $userId');
        return null;
      }

      print('🔍 [ConsumerRepository] Found consumer data: $consumerResponse');

      // Get account data from accounts table
      final accountResponse = await _supabase
          .from('accounts')
          .select('full_name, full_address, mobile_no, email')
          .eq('id', userId)
          .maybeSingle();

      if (accountResponse == null) {
        print('ℹ️ [ConsumerRepository] Account not found for user: $userId');
        return null;
      }

      print('🔍 [ConsumerRepository] Found account data: $accountResponse');

      // Merge the data from both tables
      final mergedData = {
        ...consumerResponse,
        'full_name': accountResponse['full_name'] ?? '',
        'full_address': accountResponse['full_address'] ?? '',
        'mobile_no': accountResponse['mobile_no'] ?? '',
        'email': accountResponse['email'] ?? '',
      };

      return Consumer.fromJson(mergedData);
    } catch (e) {
      print('❌ [ConsumerRepository] Error fetching consumer by user ID: $e');
      print('❌ [ConsumerRepository] Error type: ${e.runtimeType}');

      if (e is PostgrestException && e.code == 'PGRST116') {
        print('ℹ️ [ConsumerRepository] Consumer not found for user: $userId');
        return null;
      }

      throw ServerFailure(
        'Failed to fetch consumer by user ID: ${e.toString()}',
      );
    }
  }
}
