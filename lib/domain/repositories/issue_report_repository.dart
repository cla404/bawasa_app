import '../entities/issue_report.dart';

abstract class IssueReportRepository {
  Future<IssueReport> submitIssueReport(IssueReport issueReport);
  Future<List<IssueReport>> getIssueReportsByConsumerId(String consumerId);
  Future<IssueReport?> getIssueReportById(int id);
}
