import '../../core/usecases/usecase.dart';
import '../entities/issue_report.dart';
import '../repositories/issue_report_repository.dart';

class GetIssueReportsByConsumerIdUseCase implements UseCase<List<IssueReport>, String> {
  final IssueReportRepository _repository;

  GetIssueReportsByConsumerIdUseCase(this._repository);

  @override
  Future<List<IssueReport>> call(String consumerId) async {
    try {
      print('🔍 [GetIssueReportsByConsumerIdUseCase] Fetching issue reports for consumer: $consumerId');
      return await _repository.getIssueReportsByConsumerId(consumerId);
    } catch (e) {
      print('❌ [GetIssueReportsByConsumerIdUseCase] Error fetching issue reports: $e');
      rethrow;
    }
  }
}


