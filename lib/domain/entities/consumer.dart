import 'package:equatable/equatable.dart';

class Consumer extends Equatable {
  final String id; // Changed from int to String for UUID support
  final String waterMeterNo;
  final String fullName;
  final String fullAddress;
  final String phone;
  final String email;
  final double previousReading;
  final double currentReading;
  final double consumptionCubicMeters;
  final double amountCurrentBilling;
  final String billingMonth;
  final String meterReadingDate;
  final String dueDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Consumer({
    required this.id,
    required this.waterMeterNo,
    required this.fullName,
    required this.fullAddress,
    required this.phone,
    required this.email,
    required this.previousReading,
    required this.currentReading,
    required this.consumptionCubicMeters,
    required this.amountCurrentBilling,
    required this.billingMonth,
    required this.meterReadingDate,
    required this.dueDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Consumer.fromJson(Map<String, dynamic> json) {
    return Consumer(
      id: json['id']?.toString() ?? '',
      waterMeterNo: json['water_meter_no'] ?? '',
      fullName: json['full_name'] ?? '',
      fullAddress: json['full_address'] ?? '',
      phone: json['mobile_no']?.toString() ?? json['phone'] ?? '',
      email: json['email'] ?? '',
      previousReading: (json['previous_reading'] ?? 0).toDouble(),
      currentReading: (json['present_reading'] ?? 0)
          .toDouble(), // Changed from current_reading to present_reading
      consumptionCubicMeters: (json['consumption_cubic_meters'] ?? 0)
          .toDouble(),
      amountCurrentBilling: (json['amount_current_billing'] ?? 0).toDouble(),
      billingMonth: json['billing_month'] ?? '',
      meterReadingDate: json['meter_reading_date'] ?? '',
      dueDate: json['due_date'] ?? '',
      status:
          json['payment_status'] ?? '', // Changed from status to payment_status
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'water_meter_no': waterMeterNo,
      'full_name': fullName,
      'full_address': fullAddress,
      'phone': phone,
      'email': email,
      'previous_reading': previousReading,
      'present_reading':
          currentReading, // Changed from current_reading to present_reading
      'consumption_cubic_meters': consumptionCubicMeters,
      'amount_current_billing': amountCurrentBilling,
      'billing_month': billingMonth,
      'meter_reading_date': meterReadingDate,
      'due_date': dueDate,
      'payment_status': status, // Changed from status to payment_status
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object> get props => [
    id,
    waterMeterNo,
    fullName,
    fullAddress,
    phone,
    email,
    previousReading,
    currentReading,
    consumptionCubicMeters,
    amountCurrentBilling,
    billingMonth,
    meterReadingDate,
    dueDate,
    status,
    createdAt,
    updatedAt,
  ];
}
