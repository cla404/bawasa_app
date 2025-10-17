import 'package:equatable/equatable.dart';

enum AccountType { consumer, admin, staff }

class UserProfile extends Equatable {
  final String id;
  final String authUserId;
  final String email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final AccountType accountType;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.authUserId,
    required this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.accountType = AccountType.consumer,
    this.isActive = true,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    authUserId,
    email,
    fullName,
    phone,
    avatarUrl,
    accountType,
    isActive,
    lastLoginAt,
    createdAt,
    updatedAt,
  ];

  UserProfile copyWith({
    String? id,
    String? authUserId,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
    AccountType? accountType,
    bool? isActive,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      authUserId: authUserId ?? this.authUserId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      accountType: accountType ?? this.accountType,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      authUserId: json['auth_user_id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      accountType: _parseAccountType(json['account_type'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_user_id': authUserId,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'account_type': accountType.name,
      'is_active': isActive,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static AccountType _parseAccountType(String? accountType) {
    switch (accountType) {
      case 'admin':
        return AccountType.admin;
      case 'staff':
        return AccountType.staff;
      case 'consumer':
      default:
        return AccountType.consumer;
    }
  }
}
