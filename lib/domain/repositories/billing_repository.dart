import '../entities/billing.dart';

abstract class BillingRepository {
  /// Get the current unpaid bill for a consumer
  Future<Billing?> getCurrentBill(String waterMeterNo);

  /// Get billing history for a consumer
  Future<List<Billing>> getBillingHistory(String waterMeterNo);

  /// Get billing history for a specific period
  Future<List<Billing>> getBillingHistoryByPeriod(
    String waterMeterNo,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get all bills for a consumer (including paid and unpaid)
  Future<List<Billing>> getAllBills(String waterMeterNo);

  /// Get overdue bills for a consumer
  Future<List<Billing>> getOverdueBills(String waterMeterNo);

  /// Get billing data by consumer ID (UUID)
  Future<List<Billing>> getBillsByConsumerId(String consumerId);
}
