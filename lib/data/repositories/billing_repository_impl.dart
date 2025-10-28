import '../../domain/entities/billing.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../core/config/supabase_config.dart';
import '../../core/error/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BillingRepositoryImpl implements BillingRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  @override
  Future<Billing?> getCurrentBill(String waterMeterNo) async {
    try {
      print(
        '🔍 [BillingRepository] Fetching current bill for water meter: $waterMeterNo',
      );

      // First, get the consumer ID from the water meter number
      final consumerResponse = await _supabase
          .from('consumers')
          .select('id')
          .eq('water_meter_no', waterMeterNo)
          .maybeSingle();

      if (consumerResponse == null) {
        print(
          'ℹ️ [BillingRepository] No consumer found for water meter: $waterMeterNo',
        );
        return null;
      }

      final consumerId = consumerResponse['id'] as String;

      // Now get the current bill from bawasa_billings table
      final response = await _supabase
          .from('bawasa_billings')
          .select('*')
          .eq('consumer_id', consumerId)
          .inFilter('payment_status', ['unpaid', 'partial', 'overdue'])
          .order('due_date', ascending: true)
          .limit(1);

      if (response.isEmpty) {
        print(
          'ℹ️ [BillingRepository] No current bill found for water meter: $waterMeterNo',
        );
        return null;
      }

      print('✅ [BillingRepository] Successfully fetched current bill');
      print('📊 [BillingRepository] Response data: $response');

      return Billing.fromJson(response.first);
    } catch (e) {
      print('❌ [BillingRepository] Error fetching current bill: $e');
      print('❌ [BillingRepository] Error type: ${e.runtimeType}');
      throw ServerFailure('Failed to fetch current bill: ${e.toString()}');
    }
  }

  @override
  Future<List<Billing>> getBillingHistory(String waterMeterNo) async {
    try {
      print(
        '🔍 [BillingRepository] Fetching billing history for water meter: $waterMeterNo',
      );

      // First, get the consumer ID from the water meter number
      final consumerResponse = await _supabase
          .from('consumers')
          .select('id')
          .eq('water_meter_no', waterMeterNo)
          .maybeSingle();

      if (consumerResponse == null) {
        print(
          'ℹ️ [BillingRepository] No consumer found for water meter: $waterMeterNo',
        );
        return [];
      }

      final consumerId = consumerResponse['id'] as String;

      // Now get billing history from bawasa_billings table
      final response = await _supabase
          .from('bawasa_billings')
          .select('*')
          .eq('consumer_id', consumerId)
          .order('due_date', ascending: false);

      print('✅ [BillingRepository] Successfully fetched billing history');
      print('📊 [BillingRepository] Response data: $response');

      return (response as List).map((json) => Billing.fromJson(json)).toList();
    } catch (e) {
      print('❌ [BillingRepository] Error fetching billing history: $e');
      print('❌ [BillingRepository] Error type: ${e.runtimeType}');
      throw ServerFailure('Failed to fetch billing history: ${e.toString()}');
    }
  }

  @override
  Future<List<Billing>> getBillingHistoryByPeriod(
    String waterMeterNo,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      print(
        '🔍 [BillingRepository] Fetching billing history for period: $startDate to $endDate',
      );

      // First, get the consumer ID from the water meter number
      final consumerResponse = await _supabase
          .from('consumers')
          .select('id')
          .eq('water_meter_no', waterMeterNo)
          .maybeSingle();

      if (consumerResponse == null) {
        print(
          'ℹ️ [BillingRepository] No consumer found for water meter: $waterMeterNo',
        );
        return [];
      }

      final consumerId = consumerResponse['id'] as String;

      // Now get billing history for the period from bawasa_billings table
      final response = await _supabase
          .from('bawasa_billings')
          .select('*')
          .eq('consumer_id', consumerId)
          .gte('due_date', startDate.toIso8601String().split('T')[0])
          .lte('due_date', endDate.toIso8601String().split('T')[0])
          .order('due_date', ascending: false);

      print(
        '✅ [BillingRepository] Successfully fetched billing history for period',
      );
      print('📊 [BillingRepository] Response data: $response');

      return (response as List).map((json) => Billing.fromJson(json)).toList();
    } catch (e) {
      print(
        '❌ [BillingRepository] Error fetching billing history for period: $e',
      );
      print('❌ [BillingRepository] Error type: ${e.runtimeType}');
      throw ServerFailure(
        'Failed to fetch billing history for period: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<Billing>> getAllBills(String waterMeterNo) async {
    try {
      print(
        '🔍 [BillingRepository] Fetching all bills for water meter: $waterMeterNo',
      );

      // First, get the consumer ID from the water meter number
      final consumerResponse = await _supabase
          .from('consumers')
          .select('id')
          .eq('water_meter_no', waterMeterNo)
          .maybeSingle();

      if (consumerResponse == null) {
        print(
          'ℹ️ [BillingRepository] No consumer found for water meter: $waterMeterNo',
        );
        return [];
      }

      final consumerId = consumerResponse['id'] as String;

      // Now get all bills from bawasa_billings table
      final response = await _supabase
          .from('bawasa_billings')
          .select('*')
          .eq('consumer_id', consumerId)
          .order('due_date', ascending: false);

      print('✅ [BillingRepository] Successfully fetched all bills');
      print('📊 [BillingRepository] Response data: $response');

      return (response as List).map((json) => Billing.fromJson(json)).toList();
    } catch (e) {
      print('❌ [BillingRepository] Error fetching all bills: $e');
      print('❌ [BillingRepository] Error type: ${e.runtimeType}');
      throw ServerFailure('Failed to fetch all bills: ${e.toString()}');
    }
  }

  @override
  Future<List<Billing>> getOverdueBills(String waterMeterNo) async {
    try {
      print(
        '🔍 [BillingRepository] Fetching overdue bills for water meter: $waterMeterNo',
      );

      // First, get the consumer ID from the water meter number
      final consumerResponse = await _supabase
          .from('consumers')
          .select('id')
          .eq('water_meter_no', waterMeterNo)
          .maybeSingle();

      if (consumerResponse == null) {
        print(
          'ℹ️ [BillingRepository] No consumer found for water meter: $waterMeterNo',
        );
        return [];
      }

      final consumerId = consumerResponse['id'] as String;
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Now get overdue bills from bawasa_billings table
      final response = await _supabase
          .from('bawasa_billings')
          .select('*')
          .eq('consumer_id', consumerId)
          .inFilter('payment_status', ['unpaid', 'partial'])
          .lt('due_date', today)
          .order('due_date', ascending: false);

      print('✅ [BillingRepository] Successfully fetched overdue bills');
      print('📊 [BillingRepository] Response data: $response');

      return (response as List).map((json) => Billing.fromJson(json)).toList();
    } catch (e) {
      print('❌ [BillingRepository] Error fetching overdue bills: $e');
      print('❌ [BillingRepository] Error type: ${e.runtimeType}');
      throw ServerFailure('Failed to fetch overdue bills: ${e.toString()}');
    }
  }

  @override
  Future<List<Billing>> getBillsByConsumerId(String consumerId) async {
    try {
      print(
        '🔍 [BillingRepository] Fetching bills by consumer ID: $consumerId',
      );

      // Get all bills for this consumer directly from bawasa_billings table
      final response = await _supabase
          .from('bawasa_billings')
          .select('*')
          .eq('consumer_id', consumerId)
          .order('due_date', ascending: false);

      print('✅ [BillingRepository] Successfully fetched bills by consumer ID');
      print('📊 [BillingRepository] Response data: $response');

      return (response as List).map((json) => Billing.fromJson(json)).toList();
    } catch (e) {
      print('❌ [BillingRepository] Error fetching bills by consumer ID: $e');
      print('❌ [BillingRepository] Error type: ${e.runtimeType}');

      if (e is PostgrestException && e.code == 'PGRST116') {
        print('ℹ️ [BillingRepository] Consumer not found with ID: $consumerId');
        return [];
      }

      throw ServerFailure(
        'Failed to fetch bills by consumer ID: ${e.toString()}',
      );
    }
  }
}
