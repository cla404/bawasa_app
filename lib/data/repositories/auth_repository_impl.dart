import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user.dart' as domain;
import '../../domain/entities/auth_credentials.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseAuthDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<AuthResult> signIn(AuthCredentials credentials) async {
    try {
      final response = await _remoteDataSource.signIn(credentials);

      if (response.user != null) {
        return AuthResult.success(message: 'Sign in successful');
      } else {
        return AuthResult.failure(
          message: 'Sign in failed',
          errorCode: 'SIGN_IN_FAILED',
        );
      }
    } catch (e) {
      return AuthResult.failure(
        message: _getErrorMessage(e),
        errorCode: 'SIGN_IN_ERROR',
      );
    }
  }

  @override
  Future<AuthResult> signUp(SignUpCredentials credentials) async {
    try {
      final response = await _remoteDataSource.signUp(credentials);

      if (response.user != null) {
        return AuthResult.success(
          message:
              'Sign up successful. Please check your email for confirmation.',
        );
      } else {
        return AuthResult.failure(
          message: 'Sign up failed',
          errorCode: 'SIGN_UP_FAILED',
        );
      }
    } catch (e) {
      return AuthResult.failure(
        message: _getErrorMessage(e),
        errorCode: 'SIGN_UP_ERROR',
      );
    }
  }

  @override
  Future<AuthResult> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return AuthResult.success(message: 'Sign out successful');
    } catch (e) {
      return AuthResult.failure(
        message: _getErrorMessage(e),
        errorCode: 'SIGN_OUT_ERROR',
      );
    }
  }

  @override
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _remoteDataSource.resetPassword(email);
      return AuthResult.success(
        message: 'Password reset email sent successfully',
      );
    } catch (e) {
      return AuthResult.failure(
        message: _getErrorMessage(e),
        errorCode: 'RESET_PASSWORD_ERROR',
      );
    }
  }

  @override
  Future<AuthResult> resendConfirmationEmail(String email) async {
    try {
      await _remoteDataSource.resendConfirmationEmail(email);
      return AuthResult.success(
        message: 'Confirmation email sent successfully',
      );
    } catch (e) {
      return AuthResult.failure(
        message: _getErrorMessage(e),
        errorCode: 'RESEND_CONFIRMATION_ERROR',
      );
    }
  }

  @override
  Future<AuthResult> updateProfile(UpdateProfileParams params) async {
    try {
      final response = await _remoteDataSource.updateProfile(params);

      if (response.user != null) {
        return AuthResult.success(message: 'Profile updated successfully');
      } else {
        return AuthResult.failure(
          message: 'Profile update failed',
          errorCode: 'UPDATE_PROFILE_FAILED',
        );
      }
    } catch (e) {
      return AuthResult.failure(
        message: _getErrorMessage(e),
        errorCode: 'UPDATE_PROFILE_ERROR',
      );
    }
  }

  @override
  domain.User? getCurrentUser() {
    final supabaseUser = _remoteDataSource.getCurrentUser();
    print('AuthRepository: Supabase user: ${supabaseUser?.email ?? 'null'}');
    final domainUser = supabaseUser != null
        ? _mapSupabaseUserToUser(supabaseUser)
        : null;
    print('AuthRepository: Mapped domain user: ${domainUser?.email ?? 'null'}');
    return domainUser;
  }

  @override
  Stream<domain.User?> get authStateChanges {
    return _remoteDataSource.authStateChanges.map((authState) {
      final supabaseUser = authState.session?.user;
      return supabaseUser != null ? _mapSupabaseUserToUser(supabaseUser) : null;
    });
  }

  domain.User _mapSupabaseUserToUser(User supabaseUser) {
    return domain.User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      fullName: supabaseUser.userMetadata?['full_name'],
      phone: supabaseUser.userMetadata?['phone'],
      avatarUrl: supabaseUser.userMetadata?['avatar_url'],
      createdAt: supabaseUser.createdAt != null
          ? DateTime.tryParse(supabaseUser.createdAt!)
          : null,
      updatedAt: supabaseUser.updatedAt != null
          ? DateTime.tryParse(supabaseUser.updatedAt!)
          : null,
      emailConfirmedAt: supabaseUser.emailConfirmedAt != null
          ? DateTime.tryParse(supabaseUser.emailConfirmedAt!)
          : null,
    );
  }

  String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      return error.message;
    } else if (error is Exception) {
      return error.toString();
    } else {
      return 'An unexpected error occurred';
    }
  }
}
