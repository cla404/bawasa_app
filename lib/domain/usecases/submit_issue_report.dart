import '../../core/usecases/usecase.dart';
import '../entities/issue_report.dart';
import '../repositories/issue_report_repository.dart';

class SubmitIssueReport implements UseCase<IssueReport, IssueReport> {
  final IssueReportRepository repository;

  SubmitIssueReport(this.repository);

  @override
  Future<IssueReport> call(IssueReport params) async {
    return await repository.submitIssueReport(params);
  }
}
