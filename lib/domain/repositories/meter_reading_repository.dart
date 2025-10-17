import '../entities/meter_reading.dart';
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
}
