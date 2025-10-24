import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/meter_reading.dart';
import '../../domain/usecases/meter_reading_usecases.dart';
import 'dart:io';

// Events
abstract class MeterReadingEvent extends Equatable {
  const MeterReadingEvent();

  @override
  List<Object?> get props => [];
}

class LoadMeterReadings extends MeterReadingEvent {}

class LoadLatestMeterReading extends MeterReadingEvent {}

class SubmitMeterReading extends MeterReadingEvent {
  final String meterType;
  final double readingValue;
  final DateTime readingDate;
  final String? notes;
  final File? photoFile;

  const SubmitMeterReading({
    required this.meterType,
    required this.readingValue,
    required this.readingDate,
    this.notes,
    this.photoFile,
  });

  @override
  List<Object?> get props => [
    meterType,
    readingValue,
    readingDate,
    notes,
    photoFile,
  ];
}

class UpdateMeterReading extends MeterReadingEvent {
  final MeterReading reading;

  const UpdateMeterReading(this.reading);

  @override
  List<Object?> get props => [reading];
}

class DeleteMeterReading extends MeterReadingEvent {
  final String readingId;

  const DeleteMeterReading(this.readingId);

  @override
  List<Object?> get props => [readingId];
}

// States
abstract class MeterReadingState extends Equatable {
  const MeterReadingState();

  @override
  List<Object?> get props => [];
}

class MeterReadingInitial extends MeterReadingState {}

class MeterReadingLoading extends MeterReadingState {}

class MeterReadingLoaded extends MeterReadingState {
  final List<MeterReading> readings;
  final MeterReading? latestReading;

  const MeterReadingLoaded({required this.readings, this.latestReading});

  @override
  List<Object?> get props => [readings, latestReading];
}

class MeterReadingError extends MeterReadingState {
  final String message;

  const MeterReadingError(this.message);

  @override
  List<Object?> get props => [message];
}

class MeterReadingSubmitted extends MeterReadingState {
  final MeterReading reading;

  const MeterReadingSubmitted(this.reading);

  @override
  List<Object?> get props => [reading];
}

class MeterReadingUpdated extends MeterReadingState {
  final MeterReading reading;

  const MeterReadingUpdated(this.reading);

  @override
  List<Object?> get props => [reading];
}

class MeterReadingDeleted extends MeterReadingState {
  final String readingId;

  const MeterReadingDeleted(this.readingId);

  @override
  List<Object?> get props => [readingId];
}

// BLoC
class MeterReadingBloc extends Bloc<MeterReadingEvent, MeterReadingState> {
  final GetUserMeterReadingsUseCase _getUserMeterReadingsUseCase;
  final GetLatestMeterReadingUseCase _getLatestMeterReadingUseCase;
  final SubmitMeterReadingUseCase _submitMeterReadingUseCase;
  final SubmitMeterReadingWithPhotoUseCase _submitMeterReadingWithPhotoUseCase;
  final UpdateMeterReadingUseCase _updateMeterReadingUseCase;
  final DeleteMeterReadingUseCase _deleteMeterReadingUseCase;

  MeterReadingBloc({
    required GetUserMeterReadingsUseCase getUserMeterReadingsUseCase,
    required GetLatestMeterReadingUseCase getLatestMeterReadingUseCase,
    required SubmitMeterReadingUseCase submitMeterReadingUseCase,
    required SubmitMeterReadingWithPhotoUseCase
    submitMeterReadingWithPhotoUseCase,
    required UpdateMeterReadingUseCase updateMeterReadingUseCase,
    required DeleteMeterReadingUseCase deleteMeterReadingUseCase,
  }) : _getUserMeterReadingsUseCase = getUserMeterReadingsUseCase,
       _getLatestMeterReadingUseCase = getLatestMeterReadingUseCase,
       _submitMeterReadingUseCase = submitMeterReadingUseCase,
       _submitMeterReadingWithPhotoUseCase = submitMeterReadingWithPhotoUseCase,
       _updateMeterReadingUseCase = updateMeterReadingUseCase,
       _deleteMeterReadingUseCase = deleteMeterReadingUseCase,
       super(MeterReadingInitial()) {
    on<LoadMeterReadings>(_onLoadMeterReadings);
    on<LoadLatestMeterReading>(_onLoadLatestMeterReading);
    on<SubmitMeterReading>(_onSubmitMeterReading);
    on<UpdateMeterReading>(_onUpdateMeterReading);
    on<DeleteMeterReading>(_onDeleteMeterReading);
  }

  Future<void> _onLoadMeterReadings(
    LoadMeterReadings event,
    Emitter<MeterReadingState> emit,
  ) async {
    print('🔄 [MeterReadingBloc] Loading meter readings...');
    emit(MeterReadingLoading());

    try {
      final readings = await _getUserMeterReadingsUseCase();
      print(
        '✅ [MeterReadingBloc] Successfully loaded ${readings.length} meter readings',
      );
      emit(MeterReadingLoaded(readings: readings));
    } catch (e) {
      print('❌ [MeterReadingBloc] Error loading meter readings: $e');
      print('❌ [MeterReadingBloc] Error type: ${e.runtimeType}');
      emit(MeterReadingError(e.toString()));
    }
  }

  Future<void> _onLoadLatestMeterReading(
    LoadLatestMeterReading event,
    Emitter<MeterReadingState> emit,
  ) async {
    print('🔄 [MeterReadingBloc] Loading latest meter reading...');
    try {
      final latestReading = await _getLatestMeterReadingUseCase();
      print(
        '✅ [MeterReadingBloc] Latest reading: ${latestReading?.readingValue}',
      );

      if (state is MeterReadingLoaded) {
        final currentState = state as MeterReadingLoaded;
        emit(
          MeterReadingLoaded(
            readings: currentState.readings,
            latestReading: latestReading,
          ),
        );
      } else {
        emit(MeterReadingLoaded(readings: [], latestReading: latestReading));
      }
    } catch (e) {
      print('❌ [MeterReadingBloc] Error loading latest meter reading: $e');
      print('❌ [MeterReadingBloc] Error type: ${e.runtimeType}');
      emit(MeterReadingError(e.toString()));
    }
  }

  Future<void> _onSubmitMeterReading(
    SubmitMeterReading event,
    Emitter<MeterReadingState> emit,
  ) async {
    print('📝 [MeterReadingBloc] Submitting meter reading...');
    print(
      '📝 [MeterReadingBloc] Event data: meterType=${event.meterType}, readingValue=${event.readingValue}, readingDate=${event.readingDate}, notes=${event.notes}, hasPhoto=${event.photoFile != null}',
    );

    try {
      MeterReading reading;

      if (event.photoFile != null) {
        // Submit with photo
        reading = await _submitMeterReadingWithPhotoUseCase(
          meterType: event.meterType,
          readingValue: event.readingValue,
          readingDate: event.readingDate,
          notes: event.notes,
          photoFile: event.photoFile,
        );
      } else {
        // Submit without photo
        reading = await _submitMeterReadingUseCase(
          meterType: event.meterType,
          readingValue: event.readingValue,
          readingDate: event.readingDate,
          notes: event.notes,
        );
      }

      print(
        '✅ [MeterReadingBloc] Successfully submitted meter reading with ID: ${reading.id}',
      );
      emit(MeterReadingSubmitted(reading));

      // COMMENTED OUT: Stop reloading meter readings due to database schema issues
      // Reload readings to update the list
      // print(
      //   '🔄 [MeterReadingBloc] Reloading meter readings after submission...',
      // );
      // add(LoadMeterReadings());
    } catch (e) {
      print('❌ [MeterReadingBloc] Error submitting meter reading: $e');
      print('❌ [MeterReadingBloc] Error type: ${e.runtimeType}');
      emit(MeterReadingError(e.toString()));
    }
  }

  Future<void> _onUpdateMeterReading(
    UpdateMeterReading event,
    Emitter<MeterReadingState> emit,
  ) async {
    try {
      final reading = await _updateMeterReadingUseCase(event.reading);
      emit(MeterReadingUpdated(reading));

      // COMMENTED OUT: Stop reloading meter readings due to database schema issues
      // Reload readings to update the list
      // add(LoadMeterReadings());
    } catch (e) {
      emit(MeterReadingError(e.toString()));
    }
  }

  Future<void> _onDeleteMeterReading(
    DeleteMeterReading event,
    Emitter<MeterReadingState> emit,
  ) async {
    try {
      await _deleteMeterReadingUseCase(event.readingId);
      emit(MeterReadingDeleted(event.readingId));

      // Reload readings to update the list
      add(LoadMeterReadings());
    } catch (e) {
      emit(MeterReadingError(e.toString()));
    }
  }
}
