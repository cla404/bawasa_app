import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_config.dart';
import '../../core/error/failures.dart';
import '../../core/injection/injection_container.dart';
import '../../domain/entities/issue_report.dart';
import '../../domain/repositories/issue_report_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/consumer_repository.dart';

class IssueReportRepositoryImpl implements IssueReportRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  @override
  Future<IssueReport> submitIssueReport(IssueReport issueReport) async {
    try {
      print('📝 [IssueReportRepository] Submitting issue report...');
      print(
        '📝 [IssueReportRepository] Issue data: ${issueReport.toInsertJson()}',
      );

      // Check if user is authenticated using custom auth system
      final authRepository = sl<AuthRepository>();
      final currentUser = authRepository.getCurrentUser();
      if (currentUser == null) {
        throw ServerFailure('User not authenticated. Please sign in first.');
      }

      print('📝 [IssueReportRepository] Current user: ${currentUser.email}');
      print('📝 [IssueReportRepository] User ID: ${currentUser.id}');

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

      final consumerId = consumer.id;
      print('📝 [IssueReportRepository] Consumer ID: $consumerId');

      final insertData = issueReport.toInsertJson();
      insertData['consumer_id'] = consumerId;
      print('📝 [IssueReportRepository] Insert data: $insertData');

      final response = await _supabase
          .from('issue_report')
          .insert(insertData)
          .select()
          .single();

      print('✅ [IssueReportRepository] Successfully submitted issue report');
      print('📊 [IssueReportRepository] Response: $response');

      return IssueReport.fromJson(response);
    } catch (e) {
      print('❌ [IssueReportRepository] Error submitting issue report: $e');
      print('❌ [IssueReportRepository] Error type: ${e.runtimeType}');
      throw ServerFailure('Failed to submit issue report: ${e.toString()}');
    }
  }

  @override
  Future<List<IssueReport>> getIssueReportsByConsumerId(
    String consumerId,
  ) async {
    try {
      print(
        '📋 [IssueReportRepository] Getting issue reports for consumer: $consumerId',
      );

      final response = await _supabase
          .from('issue_report')
          .select()
          .eq('consumer_id', consumerId)
          .order('created_at', ascending: false);

      print(
        '✅ [IssueReportRepository] Retrieved ${response.length} issue reports',
      );

      return response.map((json) => IssueReport.fromJson(json)).toList();
    } catch (e) {
      print('❌ [IssueReportRepository] Error getting issue reports: $e');
      print('❌ [IssueReportRepository] Error type: ${e.runtimeType}');
      throw ServerFailure('Failed to get issue reports: ${e.toString()}');
    }
  }

  @override
  Future<IssueReport?> getIssueReportById(int id) async {
    try {
      print('📋 [IssueReportRepository] Getting issue report by ID: $id');

      final response = await _supabase
          .from('issue_report')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        print('📋 [IssueReportRepository] No issue report found with ID: $id');
        return null;
      }

      print('✅ [IssueReportRepository] Retrieved issue report');
      return IssueReport.fromJson(response);
    } catch (e) {
      print('❌ [IssueReportRepository] Error getting issue report by ID: $e');
      print('❌ [IssueReportRepository] Error type: ${e.runtimeType}');
      throw ServerFailure('Failed to get issue report: ${e.toString()}');
    }
  }
}
