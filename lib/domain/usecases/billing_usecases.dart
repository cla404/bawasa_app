import '../entities/billing.dart';
import '../repositories/billing_repository.dart';
import '../../core/usecases/usecase.dart';
import '../../core/error/failures.dart';

/// Use case to get the current unpaid bill for a consumer
class GetCurrentBill implements UseCase<Billing?, String> {
  final BillingRepository repository;

  GetCurrentBill(this.repository);

  @override
  Future<Billing?> call(String waterMeterNo) async {
    try {
      return await repository.getCurrentBill(waterMeterNo);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}

/// Use case to get billing history for a consumer
class GetBillingHistory implements UseCase<List<Billing>, String> {
  final BillingRepository repository;

  GetBillingHistory(this.repository);

  @override
  Future<List<Billing>> call(String waterMeterNo) async {
    try {
      return await repository.getBillingHistory(waterMeterNo);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}

/// Use case to get billing history for a specific period
class GetBillingHistoryByPeriod
    implements UseCase<List<Billing>, BillingPeriodParams> {
  final BillingRepository repository;

  GetBillingHistoryByPeriod(this.repository);

  @override
  Future<List<Billing>> call(BillingPeriodParams params) async {
    try {
      return await repository.getBillingHistoryByPeriod(
        params.waterMeterNo,
        params.startDate,
        params.endDate,
      );
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}

/// Use case to get all bills for a consumer
class GetAllBills implements UseCase<List<Billing>, String> {
  final BillingRepository repository;

  GetAllBills(this.repository);

  @override
  Future<List<Billing>> call(String waterMeterNo) async {
    try {
      return await repository.getAllBills(waterMeterNo);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}

/// Use case to get overdue bills for a consumer
class GetOverdueBills implements UseCase<List<Billing>, String> {
  final BillingRepository repository;

  GetOverdueBills(this.repository);

  @override
  Future<List<Billing>> call(String waterMeterNo) async {
    try {
      return await repository.getOverdueBills(waterMeterNo);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}

/// Use case to get bills by consumer ID
class GetBillsByConsumerId implements UseCase<List<Billing>, String> {
  final BillingRepository repository;

  GetBillsByConsumerId(this.repository);

  @override
  Future<List<Billing>> call(String consumerId) async {
    try {
      return await repository.getBillsByConsumerId(consumerId);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}

/// Parameters for billing period use case
class BillingPeriodParams {
  final String waterMeterNo;
  final DateTime startDate;
  final DateTime endDate;

  BillingPeriodParams({
    required this.waterMeterNo,
    required this.startDate,
    required this.endDate,
  });
}
