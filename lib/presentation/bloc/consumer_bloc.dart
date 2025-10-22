import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/consumer.dart';
import '../../domain/usecases/consumer_usecases.dart';

// Events
abstract class ConsumerEvent extends Equatable {
  const ConsumerEvent();

  @override
  List<Object?> get props => [];
}

class LoadConsumerDetails extends ConsumerEvent {
  final String userId;

  const LoadConsumerDetails(this.userId);

  @override
  List<Object?> get props => [userId];
}

// States
abstract class ConsumerState extends Equatable {
  const ConsumerState();

  @override
  List<Object?> get props => [];
}

class ConsumerInitial extends ConsumerState {}

class ConsumerLoading extends ConsumerState {}

class ConsumerLoaded extends ConsumerState {
  final Consumer consumer;

  const ConsumerLoaded(this.consumer);

  @override
  List<Object?> get props => [consumer];
}

class ConsumerError extends ConsumerState {
  final String message;

  const ConsumerError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ConsumerBloc extends Bloc<ConsumerEvent, ConsumerState> {
  final GetConsumerByUserIdUseCase _getConsumerByUserIdUseCase;

  ConsumerBloc({required GetConsumerByUserIdUseCase getConsumerByUserIdUseCase})
    : _getConsumerByUserIdUseCase = getConsumerByUserIdUseCase,
      super(ConsumerInitial()) {
    on<LoadConsumerDetails>(_onLoadConsumerDetails);
  }

  Future<void> _onLoadConsumerDetails(
    LoadConsumerDetails event,
    Emitter<ConsumerState> emit,
  ) async {
    print(
      '🔄 [ConsumerBloc] Loading consumer details for user: ${event.userId}',
    );
    emit(ConsumerLoading());

    try {
      final consumer = await _getConsumerByUserIdUseCase(event.userId);

      if (consumer != null) {
        print('✅ [ConsumerBloc] Successfully loaded consumer details');
        emit(ConsumerLoaded(consumer));
      } else {
        print('ℹ️ [ConsumerBloc] No consumer found for user: ${event.userId}');
        emit(ConsumerError('No consumer details found'));
      }
    } catch (e) {
      print('❌ [ConsumerBloc] Error loading consumer details: $e');
      emit(ConsumerError(e.toString()));
    }
  }
}
