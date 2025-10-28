import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/meter_reading.dart';
import '../../domain/usecases/meter_reading_usecases.dart';

// Events
abstract class ConsumptionEvent extends Equatable {
  const ConsumptionEvent();

  @override
  List<Object> get props => [];
}

class LoadConsumptionData extends ConsumptionEvent {
  const LoadConsumptionData();
}

class RefreshConsumptionData extends ConsumptionEvent {
  const RefreshConsumptionData();
}

// States
abstract class ConsumptionState extends Equatable {
  const ConsumptionState();

  @override
  List<Object> get props => [];
}

class ConsumptionInitial extends ConsumptionState {}

class ConsumptionLoading extends ConsumptionState {}

class ConsumptionLoaded extends ConsumptionState {
  final List<MeterReading> meterReadings;
  final double totalConsumption;
  final double averageDailyConsumption;
  final double averageWeeklyConsumption;
  final double averageMonthlyConsumption;

  const ConsumptionLoaded({
    required this.meterReadings,
    required this.totalConsumption,
    required this.averageDailyConsumption,
    required this.averageWeeklyConsumption,
    required this.averageMonthlyConsumption,
  });

  @override
  List<Object> get props => [
    meterReadings,
    totalConsumption,
    averageDailyConsumption,
    averageWeeklyConsumption,
    averageMonthlyConsumption,
  ];
}

class ConsumptionError extends ConsumptionState {
  final String message;

  const ConsumptionError({required this.message});

  @override
  List<Object> get props => [message];
}

// BLoC
class ConsumptionBloc extends Bloc<ConsumptionEvent, ConsumptionState> {
  final GetUserMeterReadingsUseCase getUserMeterReadingsUseCase;

  ConsumptionBloc({required this.getUserMeterReadingsUseCase})
    : super(ConsumptionInitial()) {
    on<LoadConsumptionData>(_onLoadConsumptionData);
    on<RefreshConsumptionData>(_onRefreshConsumptionData);
  }

  Future<void> _onLoadConsumptionData(
    LoadConsumptionData event,
    Emitter<ConsumptionState> emit,
  ) async {
    emit(ConsumptionLoading());

    try {
      final meterReadings = await getUserMeterReadingsUseCase.call();

      // Calculate consumption statistics
      final totalConsumption = _calculateTotalConsumption(meterReadings);
      final averageDailyConsumption = _calculateAverageDailyConsumption(
        meterReadings,
      );
      final averageWeeklyConsumption = _calculateAverageWeeklyConsumption(
        meterReadings,
      );
      final averageMonthlyConsumption = _calculateAverageMonthlyConsumption(
        meterReadings,
      );

      emit(
        ConsumptionLoaded(
          meterReadings: meterReadings,
          totalConsumption: totalConsumption,
          averageDailyConsumption: averageDailyConsumption,
          averageWeeklyConsumption: averageWeeklyConsumption,
          averageMonthlyConsumption: averageMonthlyConsumption,
        ),
      );
    } catch (e) {
      emit(ConsumptionError(message: e.toString()));
    }
  }

  Future<void> _onRefreshConsumptionData(
    RefreshConsumptionData event,
    Emitter<ConsumptionState> emit,
  ) async {
    add(const LoadConsumptionData());
  }

  double _calculateTotalConsumption(List<MeterReading> readings) {
    if (readings.length < 2) return 0.0;

    // Sort readings by date
    final sortedReadings = List<MeterReading>.from(readings)
      ..sort((a, b) => a.readingDate.compareTo(b.readingDate));

    double totalConsumption = 0.0;
    for (int i = 1; i < sortedReadings.length; i++) {
      totalConsumption +=
          sortedReadings[i].readingValue - sortedReadings[i - 1].readingValue;
    }

    return totalConsumption;
  }

  double _calculateAverageDailyConsumption(List<MeterReading> readings) {
    if (readings.isEmpty) return 0.0;

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Filter readings from last 30 days
    final recentReadings = readings.where((reading) {
      return reading.readingDate.isAfter(thirtyDaysAgo);
    }).toList();

    if (recentReadings.length < 2) return 0.0;

    // Sort readings by date
    recentReadings.sort((a, b) => a.readingDate.compareTo(b.readingDate));

    double totalConsumption = 0.0;
    for (int i = 1; i < recentReadings.length; i++) {
      totalConsumption +=
          recentReadings[i].readingValue - recentReadings[i - 1].readingValue;
    }

    // Calculate average daily consumption
    final daysDiff = now.difference(thirtyDaysAgo).inDays;
    return daysDiff > 0 ? totalConsumption / daysDiff : 0.0;
  }

  double _calculateAverageWeeklyConsumption(List<MeterReading> readings) {
    if (readings.isEmpty) return 0.0;

    final now = DateTime.now();
    final twelveWeeksAgo = now.subtract(const Duration(days: 84)); // 12 weeks

    // Filter readings from last 12 weeks
    final recentReadings = readings.where((reading) {
      return reading.readingDate.isAfter(twelveWeeksAgo);
    }).toList();

    if (recentReadings.length < 2) return 0.0;

    // Sort readings by date
    recentReadings.sort((a, b) => a.readingDate.compareTo(b.readingDate));

    double totalConsumption = 0.0;
    for (int i = 1; i < recentReadings.length; i++) {
      totalConsumption +=
          recentReadings[i].readingValue - recentReadings[i - 1].readingValue;
    }

    // Calculate average weekly consumption
    final weeksDiff = now.difference(twelveWeeksAgo).inDays / 7;
    return weeksDiff > 0 ? totalConsumption / weeksDiff : 0.0;
  }

  double _calculateAverageMonthlyConsumption(List<MeterReading> readings) {
    if (readings.isEmpty) return 0.0;

    final now = DateTime.now();
    final twelveMonthsAgo = DateTime(now.year - 1, now.month);

    // Filter readings from last 12 months
    final recentReadings = readings.where((reading) {
      return reading.readingDate.isAfter(twelveMonthsAgo);
    }).toList();

    if (recentReadings.length < 2) return 0.0;

    // Sort readings by date
    recentReadings.sort((a, b) => a.readingDate.compareTo(b.readingDate));

    double totalConsumption = 0.0;
    for (int i = 1; i < recentReadings.length; i++) {
      totalConsumption +=
          recentReadings[i].readingValue - recentReadings[i - 1].readingValue;
    }

    // Calculate average monthly consumption
    final monthsDiff =
        (now.year - twelveMonthsAgo.year) * 12 +
        (now.month - twelveMonthsAgo.month);
    return monthsDiff > 0 ? totalConsumption / monthsDiff : 0.0;
  }
}
