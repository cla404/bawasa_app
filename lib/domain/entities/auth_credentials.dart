import 'package:equatable/equatable.dart';

class AuthCredentials extends Equatable {
  final String email;
  final String password;

  const AuthCredentials({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class SignUpCredentials extends Equatable {
  final String email;
  final String password;
  final String? fullName;
  final String? phone;

  const SignUpCredentials({
    required this.email,
    required this.password,
    this.fullName,
    this.phone,
  });

  @override
  List<Object?> get props => [email, password, fullName, phone];
}

class UpdateProfileParams extends Equatable {
  final String? fullName;
  final String? phone;
  final String? avatarUrl;

  const UpdateProfileParams({this.fullName, this.phone, this.avatarUrl});

  @override
  List<Object?> get props => [fullName, phone, avatarUrl];
}
