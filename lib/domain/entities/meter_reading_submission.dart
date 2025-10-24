import 'package:equatable/equatable.dart';

class MeterReadingSubmission extends Equatable {
  final String id;
  final double? previousReading;
  final double? presentReading;
  final int? numberOfConsumption;
  final String? remarks;
  final DateTime createdAt;
  final String? consumerId;
  final String? meterImage;

  const MeterReadingSubmission({
    required this.id,
    this.previousReading,
    this.presentReading,
    this.numberOfConsumption,
    this.remarks,
    required this.createdAt,
    this.consumerId,
    this.meterImage,
  });

  factory MeterReadingSubmission.fromJson(Map<String, dynamic> json) {
    return MeterReadingSubmission(
      id: json['id'] as String,
      previousReading: json['previous_reading']?.toDouble(),
      presentReading: json['present_reading']?.toDouble(),
      numberOfConsumption: json['number_of_consumption'] as int?,
      remarks: json['remarks'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      consumerId: json['consumer_id'] as String?,
      meterImage: json['meter_image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'previous_reading': previousReading,
      'present_reading': presentReading,
      'number_of_consumption': numberOfConsumption,
      'remarks': remarks,
      'created_at': createdAt.toIso8601String(),
      'consumer_id': consumerId,
      'meter_image': meterImage,
    };
  }

  MeterReadingSubmission copyWith({
    String? id,
    double? previousReading,
    double? presentReading,
    int? numberOfConsumption,
    String? remarks,
    DateTime? createdAt,
    String? consumerId,
    String? meterImage,
  }) {
    return MeterReadingSubmission(
      id: id ?? this.id,
      previousReading: previousReading ?? this.previousReading,
      presentReading: presentReading ?? this.presentReading,
      numberOfConsumption: numberOfConsumption ?? this.numberOfConsumption,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      consumerId: consumerId ?? this.consumerId,
      meterImage: meterImage ?? this.meterImage,
    );
  }

  @override
  List<Object?> get props => [
    id,
    previousReading,
    presentReading,
    numberOfConsumption,
    remarks,
    createdAt,
    consumerId,
    meterImage,
  ];
}
