import '../../domain/entities/user.dart' as domain;
import '../../domain/entities/auth_credentials.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/custom_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../services/custom_auth_service.dart';
import '../../core/config/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CustomAuthRepositoryImpl implements AuthRepository {
  static CustomUser? _currentUser;
  static const String _userKey = 'current_user';

  @override
  Future<AuthResult> signIn(AuthCredentials credentials) async {
    try {
      print(
        '🔐 [CustomAuthRepository] Attempting sign in for: ${credentials.email}',
      );

      final result = await CustomAuthService.signInWithAccounts(
        email: credentials.email,
        password: credentials.password,
      );

      if (result['success'] == true) {
        // Store user data locally
        print(
          '🔍 [CustomAuthRepository] Creating user from data: ${result['user']}',
        );
        try {
          _currentUser = CustomUser.fromMap(result['user']);
          print(
            '✅ [CustomAuthRepository] User created successfully: ${_currentUser!.email}',
          );
          await _saveUserToStorage(_currentUser!);

          // Update last_signed_in timestamp in accounts table
          await _updateLastSignedIn(_currentUser!.id);
        } catch (e) {
          print('❌ [CustomAuthRepository] Error creating user: $e');
          return AuthResult.failure(
            message: 'Failed to process user data: $e',
            errorCode: 'USER_CREATION_ERROR',
          );
        }

        print('✅ [CustomAuthRepository] Sign in successful');
        return AuthResult.success(message: 'Sign in successful');
      } else {
        print('❌ [CustomAuthRepository] Sign in failed: ${result['error']}');
        return AuthResult.failure(
          message: result['error'] ?? 'Sign in failed',
          errorCode: 'SIGN_IN_FAILED',
        );
      }
    } catch (e) {
      print('❌ [CustomAuthRepository] Sign in error: $e');
      return AuthResult.failure(
        message: e.toString(),
        errorCode: 'SIGN_IN_ERROR',
      );
    }
  }

  @override
  Future<AuthResult> signUp(SignUpCredentials credentials) async {
    // For now, we'll return an error since sign up should be done through the web admin
    return AuthResult.failure(
      message:
          'Sign up is not available in the mobile app. Please contact your administrator.',
      errorCode: 'SIGN_UP_NOT_AVAILABLE',
    );
  }

  @override
  Future<AuthResult> signOut() async {
    try {
      await CustomAuthService.signOut();
      _currentUser = null;
      await _clearUserFromStorage();

      print('✅ [CustomAuthRepository] Sign out successful');
      return AuthResult.success(message: 'Sign out successful');
    } catch (e) {
      print('❌ [CustomAuthRepository] Sign out error: $e');
      return AuthResult.failure(
        message: e.toString(),
        errorCode: 'SIGN_OUT_ERROR',
      );
    }
  }

  @override
  Future<AuthResult> resetPassword(String email) async {
    // For now, we'll return an error since password reset should be done through the web admin
    return AuthResult.failure(
      message:
          'Password reset is not available in the mobile app. Please contact your administrator.',
      errorCode: 'RESET_PASSWORD_NOT_AVAILABLE',
    );
  }

  @override
  Future<AuthResult> resendConfirmationEmail(String email) async {
    // Not applicable for custom authentication
    return AuthResult.failure(
      message: 'Email confirmation is not required for this account type.',
      errorCode: 'RESEND_CONFIRMATION_NOT_AVAILABLE',
    );
  }

  @override
  Future<AuthResult> updateProfile(UpdateProfileParams params) async {
    // For now, we'll return an error since profile updates should be done through the web admin
    return AuthResult.failure(
      message:
          'Profile updates are not available in the mobile app. Please contact your administrator.',
      errorCode: 'UPDATE_PROFILE_NOT_AVAILABLE',
    );
  }

  @override
  domain.User? getCurrentUser() {
    if (_currentUser != null) {
      return _mapCustomUserToUser(_currentUser!);
    }
    return null;
  }

  @override
  Stream<domain.User?> get authStateChanges {
    // For custom authentication, we'll use a simple stream that emits the current user
    // In a real implementation, you might want to implement proper session management
    return Stream.value(
      _currentUser != null ? _mapCustomUserToUser(_currentUser!) : null,
    );
  }

  // Initialize user from storage on app start
  Future<void> initializeUser() async {
    try {
      final user = await _getUserFromStorage();
      if (user != null) {
        _currentUser = user;
        print('✅ [CustomAuthRepository] User restored from storage');
      }
    } catch (e) {
      print('❌ [CustomAuthRepository] Failed to restore user from storage: $e');
    }
  }

  domain.User _mapCustomUserToUser(CustomUser customUser) {
    return domain.User(
      id: customUser.id,
      email: customUser.email,
      fullName: customUser.fullName,
      phone: customUser.phone,
      avatarUrl: null, // Custom users don't have avatar URLs
      createdAt: DateTime.tryParse(customUser.createdAt),
      updatedAt: DateTime.tryParse(customUser.updatedAt),
      emailConfirmedAt: DateTime.tryParse(
        customUser.createdAt,
      ), // Assume confirmed since they can sign in
    );
  }

  Future<void> _saveUserToStorage(CustomUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toMap());
      await prefs.setString(_userKey, userJson);
    } catch (e) {
      print('❌ [CustomAuthRepository] Failed to save user to storage: $e');
    }
  }

  Future<CustomUser?> _getUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return CustomUser.fromMap(userMap);
      }
    } catch (e) {
      print('❌ [CustomAuthRepository] Failed to get user from storage: $e');
    }
    return null;
  }

  Future<void> _clearUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (e) {
      print('❌ [CustomAuthRepository] Failed to clear user from storage: $e');
    }
  }

  Future<void> _updateLastSignedIn(String userId) async {
    try {
      print(
        '🔄 [CustomAuthRepository] Updating last_signed_in for user: $userId',
      );

      final supabase = SupabaseConfig.client;
      final now = DateTime.now().toIso8601String();

      await supabase
          .from('accounts')
          .update({'last_signed_in': now})
          .eq('id', userId);

      print('✅ [CustomAuthRepository] Successfully updated last_signed_in');
    } catch (e) {
      print('❌ [CustomAuthRepository] Error updating last_signed_in: $e');
    }
  }
}
