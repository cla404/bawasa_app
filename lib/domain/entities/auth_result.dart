import 'package:equatable/equatable.dart';

class AuthResult extends Equatable {
  final bool isSuccess;
  final String? message;
  final String? errorCode;

  const AuthResult({required this.isSuccess, this.message, this.errorCode});

  @override
  List<Object?> get props => [isSuccess, message, errorCode];

  factory AuthResult.success({String? message}) {
    return AuthResult(isSuccess: true, message: message);
  }

  factory AuthResult.failure({required String message, String? errorCode}) {
    return AuthResult(isSuccess: false, message: message, errorCode: errorCode);
  }
}
