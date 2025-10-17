import 'package:equatable/equatable.dart';
import '../../../domain/entities/auth_credentials.dart';
import '../../../domain/entities/user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class SignInRequested extends AuthEvent {
  final AuthCredentials credentials;

  const SignInRequested(this.credentials);

  @override
  List<Object> get props => [credentials];
}

class SignUpRequested extends AuthEvent {
  final SignUpCredentials credentials;

  const SignUpRequested(this.credentials);

  @override
  List<Object> get props => [credentials];
}

class SignOutRequested extends AuthEvent {}

class ResetPasswordRequested extends AuthEvent {
  final String email;

  const ResetPasswordRequested(this.email);

  @override
  List<Object> get props => [email];
}

class ResendConfirmationEmailRequested extends AuthEvent {
  final String email;

  const ResendConfirmationEmailRequested(this.email);

  @override
  List<Object> get props => [email];
}

class AuthErrorDismissed extends AuthEvent {}

class AuthSuccessDismissed extends AuthEvent {}

class AuthStateChanged extends AuthEvent {
  final User? user;

  const AuthStateChanged(this.user);

  @override
  List<Object?> get props => [user];
}
