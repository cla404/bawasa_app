import 'package:equatable/equatable.dart';

class CustomUser extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String fullAddress;
  final String consumerId; // Changed from int to String to handle UUIDs
  final String waterMeterNo;
  final String createdAt;
  final String updatedAt;
  final String
  userType; // Added to distinguish between consumer and meter_reader
  final String? status; // Status for meter readers (active, suspended, etc.)

  const CustomUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.fullAddress,
    required this.consumerId,
    required this.waterMeterNo,
    required this.createdAt,
    required this.updatedAt,
    required this.userType,
    this.status,
  });

  factory CustomUser.fromMap(Map<String, dynamic> map) {
    print('🔍 [CustomUser] Parsing map: $map');

    // Handle consumer_id conversion - now as String for UUIDs
    String consumerId = '';
    if (map['consumer_id'] != null) {
      consumerId = map['consumer_id'].toString();
    }

    print('🔍 [CustomUser] Parsed consumer_id: $consumerId');

    return CustomUser(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      fullAddress: map['full_address']?.toString() ?? '',
      consumerId: consumerId,
      waterMeterNo: map['water_meter_no']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? '',
      updatedAt: map['updated_at']?.toString() ?? '',
      userType:
          map['user_type']?.toString() ??
          'consumer', // Default to consumer for backward compatibility
      status: map['status']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'full_address': fullAddress,
      'consumer_id': consumerId,
      'water_meter_no': waterMeterNo,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'user_type': userType,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    phone,
    fullAddress,
    consumerId,
    waterMeterNo,
    createdAt,
    updatedAt,
    userType,
    status,
  ];
}
