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

      // First, get the consumer data from bawasa_consumers table
      final consumerResponse = await _supabase
          .from('bawasa_consumers')
          .select()
          .eq('id', consumerId)
          .single();

      // Then, get the account data from accounts table using consumer_id
      final accountResponse = await _supabase
          .from('accounts')
          .select('full_name, full_address, mobile_no, email')
          .eq('consumer_id', consumerId)
          .single();

      print('✅ [ConsumerRepository] Successfully fetched consumer details');
      print('📊 [ConsumerRepository] Consumer data: $consumerResponse');
      print('📊 [ConsumerRepository] Account data: $accountResponse');

      // Merge the data from both tables
      final mergedData = {
        ...consumerResponse,
        'full_name':
            accountResponse['full_name'] ?? consumerResponse['full_name'],
        'full_address':
            accountResponse['full_address'] ?? consumerResponse['full_address'],
        'mobile_no': accountResponse['mobile_no'] ?? consumerResponse['phone'],
        'email': accountResponse['email'] ?? consumerResponse['email'],
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

      // First, get the consumer_id from the accounts table
      final accountResponse = await _supabase
          .from('accounts')
          .select('consumer_id')
          .eq('id', userId)
          .single();

      if (accountResponse['consumer_id'] == null) {
        print('ℹ️ [ConsumerRepository] No consumer_id found for user: $userId');
        return null;
      }

      final consumerId = accountResponse['consumer_id'];
      print('🔍 [ConsumerRepository] Found consumer_id: $consumerId');

      // Now fetch the consumer details
      return await getConsumerDetails(consumerId.toString());
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
