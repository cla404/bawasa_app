import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? emailConfirmedAt;

  const User({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
    this.emailConfirmedAt,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    phone,
    avatarUrl,
    createdAt,
    updatedAt,
    emailConfirmedAt,
  ];

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? emailConfirmedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      emailConfirmedAt: emailConfirmedAt ?? this.emailConfirmedAt,
    );
  }
}
