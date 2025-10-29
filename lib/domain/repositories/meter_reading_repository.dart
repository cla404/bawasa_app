import '../entities/meter_reading.dart';
import '../entities/meter_reading_submission.dart';
import '../entities/consumer.dart';
import 'dart:io';

abstract class MeterReadingRepository {
  /// Get all meter readings for the current user
  Future<List<MeterReading>> getUserMeterReadings();

  /// Get meter readings for a specific date range
  Future<List<MeterReading>> getMeterReadingsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Submit a new meter reading
  Future<MeterReading> submitMeterReading(MeterReading reading);

  /// Submit a new meter reading with photo
  Future<MeterReading> submitMeterReadingWithPhoto(
    MeterReading reading,
    File? photoFile,
  );

  /// Update an existing meter reading (only if status is pending)
  Future<MeterReading> updateMeterReading(MeterReading reading);

  /// Delete a meter reading (only if status is pending)
  Future<void> deleteMeterReading(String readingId);

  /// Get the latest meter reading for the current user
  Future<MeterReading?> getLatestMeterReading();

  /// Get meter reading by ID
  Future<MeterReading?> getMeterReadingById(String readingId);

  // Meter Reader specific methods
  /// Submit a meter reading for a specific consumer (for meter readers)
  Future<MeterReadingSubmission> submitMeterReadingForConsumer(
    MeterReadingSubmission submission,
    File? meterImageFile,
  );

  /// Get all consumers for meter reader to select from
  Future<List<Consumer>> getConsumersForMeterReader();

  /// Get consumer by ID
  Future<Consumer?> getConsumerById(String consumerId);

  /// Get completed meter readings for meter reader
  Future<List<Map<String, dynamic>>> getCompletedMeterReadings();
}
