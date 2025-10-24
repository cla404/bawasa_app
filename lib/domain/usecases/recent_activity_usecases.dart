import '../entities/recent_activity.dart';
import '../repositories/recent_activity_repository.dart';

class GetRecentActivitiesUseCase {
  final RecentActivityRepository _repository;

  GetRecentActivitiesUseCase(this._repository);

  Future<List<RecentActivity>> call({int limit = 10, DateTime? since}) async {
    return await _repository.getRecentActivities(limit: limit, since: since);
  }
}
