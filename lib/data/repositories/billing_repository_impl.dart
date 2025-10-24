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

      final response = await _supabase
          .from('bawasa_consumers')
          .select()
          .eq('water_meter_no', waterMeterNo)
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

      final response = await _supabase
          .from('bawasa_consumers')
          .select()
          .eq('water_meter_no', waterMeterNo)
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

      final response = await _supabase
          .from('bawasa_consumers')
          .select()
          .eq('water_meter_no', waterMeterNo)
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

      final response = await _supabase
          .from('bawasa_consumers')
          .select()
          .eq('water_meter_no', waterMeterNo)
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

      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _supabase
          .from('bawasa_consumers')
          .select()
          .eq('water_meter_no', waterMeterNo)
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

      // First, get the water meter number from the consumer data
      final consumerResponse = await _supabase
          .from('bawasa_consumers')
          .select('water_meter_no')
          .eq('id', consumerId)
          .single();

      if (consumerResponse.isEmpty) {
        print('ℹ️ [BillingRepository] No consumer found with ID: $consumerId');
        return [];
      }

      final waterMeterNo = consumerResponse['water_meter_no'] as String;
      print('🔍 [BillingRepository] Found water meter number: $waterMeterNo');

      // Now fetch all bills for this water meter
      return await getAllBills(waterMeterNo);
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
