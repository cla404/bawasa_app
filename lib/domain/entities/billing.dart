import 'package:equatable/equatable.dart';

class Billing extends Equatable {
  final String id;
  final String waterMeterNo;
  final String billingMonth;
  final DateTime meterReadingDate;
  final double previousReading;
  final double presentReading;
  final double consumptionCubicMeters;
  final double consumption10OrBelow;
  final double amount10OrBelow;
  final double amount10OrBelowWithDiscount;
  final double consumptionOver10;
  final double amountOver10;
  final double amountCurrentBilling;
  final double arrearsToBePaid;
  final double totalAmountDue;
  final DateTime dueDate;
  final double? arrearsAfterDueDate;
  final String paymentStatus;
  final DateTime? paymentDate;
  final double amountPaid;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Billing({
    required this.id,
    required this.waterMeterNo,
    required this.billingMonth,
    required this.meterReadingDate,
    required this.previousReading,
    required this.presentReading,
    required this.consumptionCubicMeters,
    required this.consumption10OrBelow,
    required this.amount10OrBelow,
    required this.amount10OrBelowWithDiscount,
    required this.consumptionOver10,
    required this.amountOver10,
    required this.amountCurrentBilling,
    required this.arrearsToBePaid,
    required this.totalAmountDue,
    required this.dueDate,
    this.arrearsAfterDueDate,
    required this.paymentStatus,
    this.paymentDate,
    required this.amountPaid,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Billing.fromJson(Map<String, dynamic> json) {
    return Billing(
      id: json['id']?.toString() ?? '',
      waterMeterNo: json['water_meter_no']?.toString() ?? '',
      billingMonth: json['billing_month']?.toString() ?? '',
      meterReadingDate: DateTime.parse(
        json['meter_reading_date']?.toString() ??
            DateTime.now().toIso8601String(),
      ),
      previousReading: (json['previous_reading'] ?? 0).toDouble(),
      presentReading: (json['present_reading'] ?? 0).toDouble(),
      consumptionCubicMeters: (json['consumption_cubic_meters'] ?? 0)
          .toDouble(),
      consumption10OrBelow: (json['consumption_10_or_below'] ?? 0).toDouble(),
      amount10OrBelow: (json['amount_10_or_below'] ?? 0).toDouble(),
      amount10OrBelowWithDiscount:
          (json['amount_10_or_below_with_discount'] ?? 0).toDouble(),
      consumptionOver10: (json['consumption_over_10'] ?? 0).toDouble(),
      amountOver10: (json['amount_over_10'] ?? 0).toDouble(),
      amountCurrentBilling: (json['amount_current_billing'] ?? 0).toDouble(),
      arrearsToBePaid: (json['arrears_to_be_paid'] ?? 0).toDouble(),
      totalAmountDue: (json['total_amount_due'] ?? 0).toDouble(),
      dueDate: DateTime.parse(
        json['due_date']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      arrearsAfterDueDate: json['arrears_after_due_date'] != null
          ? (json['arrears_after_due_date'] as num).toDouble()
          : null,
      paymentStatus: json['payment_status']?.toString() ?? 'unpaid',
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'].toString())
          : null,
      amountPaid: (json['amount_paid'] ?? 0).toDouble(),
      createdAt: DateTime.parse(
        json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'water_meter_no': waterMeterNo,
      'billing_month': billingMonth,
      'meter_reading_date': meterReadingDate.toIso8601String(),
      'previous_reading': previousReading,
      'present_reading': presentReading,
      'consumption_cubic_meters': consumptionCubicMeters,
      'consumption_10_or_below': consumption10OrBelow,
      'amount_10_or_below': amount10OrBelow,
      'amount_10_or_below_with_discount': amount10OrBelowWithDiscount,
      'consumption_over_10': consumptionOver10,
      'amount_over_10': amountOver10,
      'amount_current_billing': amountCurrentBilling,
      'arrears_to_be_paid': arrearsToBePaid,
      'total_amount_due': totalAmountDue,
      'due_date': dueDate.toIso8601String(),
      'arrears_after_due_date': arrearsAfterDueDate,
      'payment_status': paymentStatus,
      'payment_date': paymentDate?.toIso8601String(),
      'amount_paid': amountPaid,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isOverdue {
    return paymentStatus == 'overdue' ||
        (paymentStatus == 'unpaid' && DateTime.now().isAfter(dueDate));
  }

  bool get isPaid {
    return paymentStatus == 'paid';
  }

  bool get isPartiallyPaid {
    return paymentStatus == 'partial';
  }

  double get remainingAmount {
    return totalAmountDue - amountPaid;
  }

  String get formattedAmount {
    return '₱${totalAmountDue.toStringAsFixed(2)}';
  }

  String get formattedDueDate {
    return '${dueDate.day}/${dueDate.month}/${dueDate.year}';
  }

  String get formattedMeterReadingDate {
    return '${meterReadingDate.day}/${meterReadingDate.month}/${meterReadingDate.year}';
  }

  @override
  List<Object?> get props => [
    id,
    waterMeterNo,
    billingMonth,
    meterReadingDate,
    previousReading,
    presentReading,
    consumptionCubicMeters,
    consumption10OrBelow,
    amount10OrBelow,
    amount10OrBelowWithDiscount,
    consumptionOver10,
    amountOver10,
    amountCurrentBilling,
    arrearsToBePaid,
    totalAmountDue,
    dueDate,
    arrearsAfterDueDate,
    paymentStatus,
    paymentDate,
    amountPaid,
    createdAt,
    updatedAt,
  ];
}
