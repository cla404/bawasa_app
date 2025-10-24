import '../../domain/entities/user.dart' as domain;
import '../../domain/entities/auth_credentials.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/custom_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../services/supabase_accounts_auth_service.dart';
import '../../core/config/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SupabaseAccountsAuthRepositoryImpl implements AuthRepository {
  static CustomUser? _currentUser;
  static const String _userKey = 'current_user';

  @override
  Future<AuthResult> signIn(AuthCredentials credentials) async {
    try {
      print(
        '🔐 [SupabaseAccountsAuthRepository] Attempting sign in for: ${credentials.email}',
      );

      final result = await SupabaseAccountsAuthService.signInWithAccounts(
        email: credentials.email,
        password: credentials.password,
      );

      if (result['success'] == true) {
        // Store user data locally
        print(
          '🔍 [SupabaseAccountsAuthRepository] Creating user from data: ${result['user']}',
        );
        try {
          _currentUser = CustomUser.fromMap(result['user']);
          print(
            '✅ [SupabaseAccountsAuthRepository] User created successfully: ${_currentUser!.email}',
          );
          await _saveUserToStorage(_currentUser!);

          // Update last_signed_in timestamp in accounts table
          await _updateLastSignedIn(_currentUser!.id);
        } catch (e) {
          print('❌ [SupabaseAccountsAuthRepository] Error creating user: $e');
          return AuthResult.failure(
            message: 'Failed to process user data: $e',
            errorCode: 'USER_CREATION_ERROR',
          );
        }

        print('✅ [SupabaseAccountsAuthRepository] Sign in successful');
        return AuthResult.success(message: 'Sign in successful');
      } else {
        print(
          '❌ [SupabaseAccountsAuthRepository] Sign in failed: ${result['error']}',
        );
        return AuthResult.failure(
          message: result['error'] ?? 'Sign in failed',
          errorCode: 'SIGN_IN_FAILED',
        );
      }
    } catch (e) {
      print('❌ [SupabaseAccountsAuthRepository] Sign in failed: $e');
      return AuthResult.failure(
        message: 'Network error. Please check your connection.',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }

  @override
  Future<AuthResult> signUp(SignUpCredentials credentials) async {
    // This implementation would need to be adapted for your signup flow
    // For now, return a failure since we're focusing on sign-in
    return AuthResult.failure(
      message: 'Sign up not implemented for accounts table authentication',
      errorCode: 'NOT_IMPLEMENTED',
    );
  }

  @override
  Future<AuthResult> signOut() async {
    try {
      print('🔐 [SupabaseAccountsAuthRepository] Signing out user');
      await SupabaseAccountsAuthService.signOut();
      _currentUser = null;
      await _clearUserFromStorage();
      return AuthResult.success(message: 'Sign out successful');
    } catch (e) {
      print('❌ [SupabaseAccountsAuthRepository] Sign out failed: $e');
      return AuthResult.failure(
        message: 'Sign out failed: $e',
        errorCode: 'SIGN_OUT_FAILED',
      );
    }
  }

  @override
  Future<AuthResult> resetPassword(String email) async {
    // This would need to be implemented based on your password reset requirements
    return AuthResult.failure(
      message:
          'Password reset not implemented for accounts table authentication',
      errorCode: 'NOT_IMPLEMENTED',
    );
  }

  @override
  Future<AuthResult> resendConfirmationEmail(String email) async {
    // This would need to be implemented based on your email confirmation requirements
    return AuthResult.failure(
      message:
          'Email confirmation not implemented for accounts table authentication',
      errorCode: 'NOT_IMPLEMENTED',
    );
  }

  @override
  Future<AuthResult> updateProfile(UpdateProfileParams params) async {
    // This would need to be implemented based on your profile update requirements
    return AuthResult.failure(
      message:
          'Profile update not implemented for accounts table authentication',
      errorCode: 'NOT_IMPLEMENTED',
    );
  }

  @override
  domain.User? getCurrentUser() {
    // Convert CustomUser to domain.User
    if (_currentUser == null) return null;

    return domain.User(
      id: _currentUser!.id,
      email: _currentUser!.email,
      fullName: _currentUser!.fullName,
      phone: _currentUser!.phone,
      avatarUrl: null, // CustomUser doesn't have avatarUrl
      createdAt: _parseDateTime(_currentUser!.createdAt),
      updatedAt: _parseDateTime(_currentUser!.updatedAt),
      emailConfirmedAt: null, // CustomUser doesn't have email confirmation
    );
  }

  @override
  CustomUser? getCurrentCustomUser() {
    return _currentUser;
  }

  @override
  Stream<domain.User?> get authStateChanges {
    // Return a stream that emits the current user
    // This is a simplified implementation - in a real app you might want
    // to listen to Supabase auth state changes and convert them
    return Stream.value(getCurrentUser());
  }

  /// Save user to local storage
  Future<void> _saveUserToStorage(CustomUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toMap());
      await prefs.setString(_userKey, userJson);
      print('✅ [SupabaseAccountsAuthRepository] User saved to storage');
    } catch (e) {
      print(
        '❌ [SupabaseAccountsAuthRepository] Failed to save user to storage: $e',
      );
    }
  }

  /// Clear user from local storage
  Future<void> _clearUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      print('✅ [SupabaseAccountsAuthRepository] User cleared from storage');
    } catch (e) {
      print(
        '❌ [SupabaseAccountsAuthRepository] Failed to clear user from storage: $e',
      );
    }
  }

  /// Update last_signed_in timestamp in accounts table
  Future<void> _updateLastSignedIn(String userId) async {
    try {
      // Parse userId as int since accounts table uses integer IDs
      final accountId = int.parse(userId);
      await SupabaseConfig.client
          .from('accounts')
          .update({'last_signed_in': DateTime.now().toIso8601String()})
          .eq('id', accountId);
      print(
        '✅ [SupabaseAccountsAuthRepository] Last signed in timestamp updated for user ID: $accountId',
      );
    } catch (e) {
      print(
        '❌ [SupabaseAccountsAuthRepository] Failed to update last signed in: $e',
      );
      // Don't throw error as this is not critical
    }
  }

  /// Load user from storage on app startup
  Future<void> loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        final userMap = jsonDecode(userJson);
        _currentUser = CustomUser.fromMap(userMap);
        print(
          '✅ [SupabaseAccountsAuthRepository] User loaded from storage: ${_currentUser!.email}',
        );
      }
    } catch (e) {
      print(
        '❌ [SupabaseAccountsAuthRepository] Failed to load user from storage: $e',
      );
    }
  }

  /// Parse date string to DateTime
  DateTime? _parseDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      print(
        '❌ [SupabaseAccountsAuthRepository] Failed to parse date: $dateString',
      );
      return null;
    }
  }
}
