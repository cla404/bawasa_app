import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/billing.dart';
import '../../domain/usecases/billing_usecases.dart';
import '../../core/error/failures.dart';

// Events
abstract class BillingEvent extends Equatable {
  const BillingEvent();

  @override
  List<Object> get props => [];
}

class LoadCurrentBill extends BillingEvent {
  final String waterMeterNo;

  const LoadCurrentBill(this.waterMeterNo);

  @override
  List<Object> get props => [waterMeterNo];
}

class LoadBillingHistory extends BillingEvent {
  final String waterMeterNo;

  const LoadBillingHistory(this.waterMeterNo);

  @override
  List<Object> get props => [waterMeterNo];
}

class LoadBillingHistoryByPeriod extends BillingEvent {
  final String waterMeterNo;
  final DateTime startDate;
  final DateTime endDate;

  const LoadBillingHistoryByPeriod({
    required this.waterMeterNo,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [waterMeterNo, startDate, endDate];
}

class LoadAllBills extends BillingEvent {
  final String waterMeterNo;

  const LoadAllBills(this.waterMeterNo);

  @override
  List<Object> get props => [waterMeterNo];
}

class LoadOverdueBills extends BillingEvent {
  final String waterMeterNo;

  const LoadOverdueBills(this.waterMeterNo);

  @override
  List<Object> get props => [waterMeterNo];
}

class LoadBillsByConsumerId extends BillingEvent {
  final String consumerId;

  const LoadBillsByConsumerId(this.consumerId);

  @override
  List<Object> get props => [consumerId];
}

class RefreshBillingData extends BillingEvent {
  final String waterMeterNo;

  const RefreshBillingData(this.waterMeterNo);

  @override
  List<Object> get props => [waterMeterNo];
}

// States
abstract class BillingState extends Equatable {
  const BillingState();

  @override
  List<Object?> get props => [];
}

class BillingInitial extends BillingState {}

class BillingLoading extends BillingState {}

class BillingLoaded extends BillingState {
  final Billing? currentBill;
  final List<Billing> billingHistory;
  final List<Billing> overdueBills;

  const BillingLoaded({
    this.currentBill,
    required this.billingHistory,
    required this.overdueBills,
  });

  @override
  List<Object?> get props => [currentBill, billingHistory, overdueBills];
}

class BillingError extends BillingState {
  final String message;

  const BillingError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc
class BillingBloc extends Bloc<BillingEvent, BillingState> {
  final GetCurrentBill getCurrentBill;
  final GetBillingHistory getBillingHistory;
  final GetBillingHistoryByPeriod getBillingHistoryByPeriod;
  final GetAllBills getAllBills;
  final GetOverdueBills getOverdueBills;
  final GetBillsByConsumerId getBillsByConsumerId;

  BillingBloc({
    required this.getCurrentBill,
    required this.getBillingHistory,
    required this.getBillingHistoryByPeriod,
    required this.getAllBills,
    required this.getOverdueBills,
    required this.getBillsByConsumerId,
  }) : super(BillingInitial()) {
    on<LoadCurrentBill>(_onLoadCurrentBill);
    on<LoadBillingHistory>(_onLoadBillingHistory);
    on<LoadBillingHistoryByPeriod>(_onLoadBillingHistoryByPeriod);
    on<LoadAllBills>(_onLoadAllBills);
    on<LoadOverdueBills>(_onLoadOverdueBills);
    on<LoadBillsByConsumerId>(_onLoadBillsByConsumerId);
    on<RefreshBillingData>(_onRefreshBillingData);
  }

  Future<void> _onLoadCurrentBill(
    LoadCurrentBill event,
    Emitter<BillingState> emit,
  ) async {
    emit(BillingLoading());

    try {
      final currentBill = await getCurrentBill(event.waterMeterNo);
      emit(
        BillingLoaded(
          currentBill: currentBill,
          billingHistory: [],
          overdueBills: [],
        ),
      );
    } catch (e) {
      emit(BillingError(_mapFailureToMessage(e as Failure)));
    }
  }

  Future<void> _onLoadBillingHistory(
    LoadBillingHistory event,
    Emitter<BillingState> emit,
  ) async {
    emit(BillingLoading());

    try {
      final billingHistory = await getBillingHistory(event.waterMeterNo);
      emit(
        BillingLoaded(
          currentBill: null,
          billingHistory: billingHistory,
          overdueBills: [],
        ),
      );
    } catch (e) {
      emit(BillingError(_mapFailureToMessage(e as Failure)));
    }
  }

  Future<void> _onLoadBillingHistoryByPeriod(
    LoadBillingHistoryByPeriod event,
    Emitter<BillingState> emit,
  ) async {
    emit(BillingLoading());

    try {
      final billingHistory = await getBillingHistoryByPeriod(
        BillingPeriodParams(
          waterMeterNo: event.waterMeterNo,
          startDate: event.startDate,
          endDate: event.endDate,
        ),
      );
      emit(
        BillingLoaded(
          currentBill: null,
          billingHistory: billingHistory,
          overdueBills: [],
        ),
      );
    } catch (e) {
      emit(BillingError(_mapFailureToMessage(e as Failure)));
    }
  }

  Future<void> _onLoadAllBills(
    LoadAllBills event,
    Emitter<BillingState> emit,
  ) async {
    emit(BillingLoading());

    try {
      final allBills = await getAllBills(event.waterMeterNo);
      emit(
        BillingLoaded(
          currentBill: null,
          billingHistory: allBills,
          overdueBills: [],
        ),
      );
    } catch (e) {
      emit(BillingError(_mapFailureToMessage(e as Failure)));
    }
  }

  Future<void> _onLoadOverdueBills(
    LoadOverdueBills event,
    Emitter<BillingState> emit,
  ) async {
    emit(BillingLoading());

    try {
      final overdueBills = await getOverdueBills(event.waterMeterNo);
      emit(
        BillingLoaded(
          currentBill: null,
          billingHistory: [],
          overdueBills: overdueBills,
        ),
      );
    } catch (e) {
      emit(BillingError(_mapFailureToMessage(e as Failure)));
    }
  }

  Future<void> _onLoadBillsByConsumerId(
    LoadBillsByConsumerId event,
    Emitter<BillingState> emit,
  ) async {
    emit(BillingLoading());

    try {
      final allBills = await getBillsByConsumerId(event.consumerId);
      emit(
        BillingLoaded(
          currentBill: null,
          billingHistory: allBills,
          overdueBills: [],
        ),
      );
    } catch (e) {
      emit(BillingError(_mapFailureToMessage(e as Failure)));
    }
  }

  Future<void> _onRefreshBillingData(
    RefreshBillingData event,
    Emitter<BillingState> emit,
  ) async {
    emit(BillingLoading());

    try {
      // Load current bill and billing history simultaneously
      final currentBill = await getCurrentBill(event.waterMeterNo);
      final billingHistory = await getBillingHistory(event.waterMeterNo);
      final overdueBills = await getOverdueBills(event.waterMeterNo);

      emit(
        BillingLoaded(
          currentBill: currentBill,
          billingHistory: billingHistory,
          overdueBills: overdueBills,
        ),
      );
    } catch (e) {
      emit(BillingError(_mapFailureToMessage(e as Failure)));
    }
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error occurred. Please try again.';
      case NetworkFailure:
        return 'Network error. Please check your connection.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
