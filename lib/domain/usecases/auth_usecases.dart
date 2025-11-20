import '../entities/auth_credentials.dart';
import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';
import '../../core/usecases/usecase.dart';

class SignInUseCase implements UseCase<AuthResult, AuthCredentials> {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  @override
  Future<AuthResult> call(AuthCredentials params) async {
    try {
      return await repository.signIn(params);
    } catch (e) {
      return AuthResult.failure(
        message: e.toString(),
        errorCode: 'SIGN_IN_ERROR',
      );
    }
  }
}

class SignUpUseCase implements UseCase<AuthResult, SignUpCredentials> {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  @override
  Future<AuthResult> call(SignUpCredentials params) async {
    try {
      return await repository.signUp(params);
    } catch (e) {
      return AuthResult.failure(
        message: e.toString(),
        errorCode: 'SIGN_UP_ERROR',
      );
    }
  }
}

class SignOutUseCase implements UseCaseNoParams<AuthResult> {
  final AuthRepository repository;

  SignOutUseCase(this.repository);

  @override
  Future<AuthResult> call() async {
    try {
      return await repository.signOut();
    } catch (e) {
      return AuthResult.failure(
        message: e.toString(),
        errorCode: 'SIGN_OUT_ERROR',
      );
    }
  }
}

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<AuthResult> call(String email, String newPassword) async {
    try {
      return await repository.resetPassword(email, newPassword);
    } catch (e) {
      return AuthResult.failure(
        message: e.toString(),
        errorCode: 'RESET_PASSWORD_ERROR',
      );
    }
  }
}

class ResendConfirmationEmailUseCase implements UseCase<AuthResult, String> {
  final AuthRepository repository;

  ResendConfirmationEmailUseCase(this.repository);

  @override
  Future<AuthResult> call(String email) async {
    try {
      return await repository.resendConfirmationEmail(email);
    } catch (e) {
      return AuthResult.failure(
        message: e.toString(),
        errorCode: 'RESEND_CONFIRMATION_ERROR',
      );
    }
  }
}
