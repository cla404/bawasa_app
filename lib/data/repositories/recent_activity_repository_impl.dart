import '../../domain/entities/recent_activity.dart';
import '../../domain/repositories/recent_activity_repository.dart';
import '../../domain/repositories/meter_reading_repository.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../domain/repositories/issue_report_repository.dart';
import '../../core/error/failures.dart';
import '../../data/repositories/supabase_accounts_auth_repository_impl.dart';
import '../../core/config/supabase_config.dart';
import 'package:get_it/get_it.dart';

class RecentActivityRepositoryImpl implements RecentActivityRepository {
  final MeterReadingRepository _meterReadingRepository;
  final BillingRepository _billingRepository;
  final IssueReportRepository _issueReportRepository;

  RecentActivityRepositoryImpl({
    required MeterReadingRepository meterReadingRepository,
    required BillingRepository billingRepository,
    required IssueReportRepository issueReportRepository,
  }) : _meterReadingRepository = meterReadingRepository,
       _billingRepository = billingRepository,
       _issueReportRepository = issueReportRepository;

  @override
  Future<List<RecentActivity>> getRecentActivities({
    int limit = 10,
    DateTime? since,
  }) async {
    try {
      print('🔍 [RecentActivityRepository] Fetching recent activities...');

      // Get current user
      final supabaseAccountsAuthRepo =
          GetIt.instance<SupabaseAccountsAuthRepositoryImpl>();
      final currentUser = supabaseAccountsAuthRepo.getCurrentUser();

      if (currentUser == null) {
        throw ServerFailure('User not authenticated. Please sign in first.');
      }

      // Get consumer data from bawasa_consumers table using consumer_id foreign key
      final consumerResponse = await SupabaseConfig.client
          .from('bawasa_consumers')
          .select('id')
          .eq('consumer_id', currentUser.id)
          .maybeSingle();

      if (consumerResponse == null) {
        throw ServerFailure(
          'Consumer account not found. Please contact support.',
        );
      }

      final consumerId = consumerResponse['id'] as String;
      print('🔍 [RecentActivityRepository] Found consumer_id: $consumerId');

      List<RecentActivity> activities = [];

      // Fetch meter readings
      try {
        final meterReadings = await _meterReadingRepository
            .getUserMeterReadings();
        final meterActivities = meterReadings
            .where(
              (reading) => since == null || reading.createdAt.isAfter(since),
            )
            .map((reading) => RecentActivity.fromMeterReading(reading.toJson()))
            .toList();
        activities.addAll(meterActivities);
        print(
          '📊 [RecentActivityRepository] Added ${meterActivities.length} meter reading activities',
        );
      } catch (e) {
        print(
          '⚠️ [RecentActivityRepository] Error fetching meter readings: $e',
        );
      }

      // Fetch bills
      try {
        final bills = await _billingRepository.getBillsByConsumerId(consumerId);
        final billActivities = bills
            .where((bill) => since == null || bill.createdAt.isAfter(since))
            .map((bill) => RecentActivity.fromBilling(bill.toJson()))
            .toList();
        activities.addAll(billActivities);
        print(
          '📊 [RecentActivityRepository] Added ${billActivities.length} billing activities',
        );
      } catch (e) {
        print('⚠️ [RecentActivityRepository] Error fetching bills: $e');
      }

      // Fetch issue reports
      try {
        final issueReports = await _issueReportRepository
            .getIssueReportsByConsumerId(consumerId);
        final issueActivities = issueReports
            .where(
              (issue) =>
                  since == null || (issue.createdAt?.isAfter(since) ?? false),
            )
            .map((issue) => RecentActivity.fromIssueReport(issue.toJson()))
            .toList();
        activities.addAll(issueActivities);
        print(
          '📊 [RecentActivityRepository] Added ${issueActivities.length} issue report activities',
        );
      } catch (e) {
        print('⚠️ [RecentActivityRepository] Error fetching issue reports: $e');
      }

      // Sort by timestamp (most recent first) and limit results
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final limitedActivities = activities.take(limit).toList();

      print(
        '✅ [RecentActivityRepository] Successfully fetched ${limitedActivities.length} recent activities',
      );
      return limitedActivities;
    } catch (e) {
      print(
        '❌ [RecentActivityRepository] Error fetching recent activities: $e',
      );
      throw ServerFailure('Failed to fetch recent activities: ${e.toString()}');
    }
  }
}
