import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/recent_activity.dart';
import '../../domain/usecases/recent_activity_usecases.dart';

// Events
abstract class RecentActivityEvent extends Equatable {
  const RecentActivityEvent();

  @override
  List<Object?> get props => [];
}

class LoadRecentActivities extends RecentActivityEvent {
  final int limit;
  final DateTime? since;

  const LoadRecentActivities({this.limit = 10, this.since});

  @override
  List<Object?> get props => [limit, since];
}

class RefreshRecentActivities extends RecentActivityEvent {
  const RefreshRecentActivities();
}

// States
abstract class RecentActivityState extends Equatable {
  const RecentActivityState();

  @override
  List<Object?> get props => [];
}

class RecentActivityInitial extends RecentActivityState {}

class RecentActivityLoading extends RecentActivityState {}

class RecentActivityLoaded extends RecentActivityState {
  final List<RecentActivity> activities;

  const RecentActivityLoaded(this.activities);

  @override
  List<Object?> get props => [activities];
}

class RecentActivityError extends RecentActivityState {
  final String message;

  const RecentActivityError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class RecentActivityBloc
    extends Bloc<RecentActivityEvent, RecentActivityState> {
  final GetRecentActivitiesUseCase _getRecentActivitiesUseCase;

  RecentActivityBloc({
    required GetRecentActivitiesUseCase getRecentActivitiesUseCase,
  }) : _getRecentActivitiesUseCase = getRecentActivitiesUseCase,
       super(RecentActivityInitial()) {
    on<LoadRecentActivities>(_onLoadRecentActivities);
    on<RefreshRecentActivities>(_onRefreshRecentActivities);
  }

  Future<void> _onLoadRecentActivities(
    LoadRecentActivities event,
    Emitter<RecentActivityState> emit,
  ) async {
    emit(RecentActivityLoading());

    try {
      final activities = await _getRecentActivitiesUseCase(
        limit: event.limit,
        since: event.since,
      );
      emit(RecentActivityLoaded(activities));
    } catch (e) {
      emit(RecentActivityError(e.toString()));
    }
  }

  Future<void> _onRefreshRecentActivities(
    RefreshRecentActivities event,
    Emitter<RecentActivityState> emit,
  ) async {
    try {
      final activities = await _getRecentActivitiesUseCase(limit: 10);
      emit(RecentActivityLoaded(activities));
    } catch (e) {
      emit(RecentActivityError(e.toString()));
    }
  }
}
