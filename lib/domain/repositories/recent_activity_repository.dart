import '../entities/recent_activity.dart';

abstract class RecentActivityRepository {
  /// Get recent activities for the current user
  /// Combines meter readings, bills, and issue reports
  Future<List<RecentActivity>> getRecentActivities({
    int limit = 10,
    DateTime? since,
  });
}
