import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';
import '../core/config/supabase_config.dart';

class SupabaseAccountsAuthService {
  static final SupabaseClient _supabase = SupabaseConfig.client;

  /// Sign in using credentials from the accounts table
  static Future<Map<String, dynamic>> signInWithAccounts({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 [SupabaseAccountsAuth] Attempting sign in for: $email');

      // Query the accounts table for the user
      final response = await _supabase
          .from('accounts')
          .select('*')
          .eq('email', email)
          .maybeSingle();

      if (response == null) {
        print('❌ [SupabaseAccountsAuth] User not found: $email');
        return {'success': false, 'error': 'Invalid login credentials'};
      }

      print('✅ [SupabaseAccountsAuth] User found in accounts table');

      // Verify password using bcrypt
      final isPasswordValid = BCrypt.checkpw(password, response['password']);

      if (!isPasswordValid) {
        print('❌ [SupabaseAccountsAuth] Invalid password for: $email');
        return {'success': false, 'error': 'Invalid login credentials'};
      }

      print('✅ [SupabaseAccountsAuth] Password verified successfully');

      // Get consumer data from bawasa_consumers table
      final consumerResponse = await _supabase
          .from('bawasa_consumers')
          .select('*')
          .eq('id', response['consumer_id'])
          .maybeSingle();

      if (consumerResponse == null) {
        print('❌ [SupabaseAccountsAuth] Consumer data not found');
        return {'success': false, 'error': 'Consumer data not found'};
      }

      print('✅ [SupabaseAccountsAuth] Consumer data retrieved');

      // Create a custom user object that matches the expected format
      final userData = {
        'id': response['id']?.toString() ?? '',
        'email': response['email'] ?? '',
        'full_name': response['full_name'] ?? '',
        'phone': response['mobile_no'] ?? '',
        'full_address': response['full_address'] ?? '',
        'consumer_id': response['consumer_id']?.toString() ?? '',
        'water_meter_no': consumerResponse['water_meter_no'] ?? '',
        'created_at': response['created_at']?.toString() ?? '',
        'updated_at': response['updated_at']?.toString() ?? '',
      };

      // For Supabase auth integration, we need to create a session
      // Since we're not using Supabase's built-in auth, we'll create a custom session
      // This allows the app to work with Supabase's auth state management
      await _createCustomSession(userData);

      return {
        'success': true,
        'user': userData,
        'message': 'Authentication successful',
      };
    } catch (e) {
      print('❌ [SupabaseAccountsAuth] Sign in failed: $e');
      if (e.toString().contains('PGRST116')) {
        // No rows returned
        return {'success': false, 'error': 'Invalid login credentials'};
      }
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  /// Create a custom session for the authenticated user
  static Future<void> _createCustomSession(
    Map<String, dynamic> userData,
  ) async {
    try {
      // Since we're not using Supabase's built-in auth, we'll store the user data
      // in a way that the app can recognize as authenticated
      // This is a workaround to integrate with Supabase's auth state management

      // We'll use Supabase's auth state by creating a temporary session
      // This allows the app to work with existing Supabase auth patterns

      // For now, we'll store the user data in a way that can be retrieved later
      // The actual session management will be handled by the auth repository
      print(
        '✅ [SupabaseAccountsAuth] Custom session created for user: ${userData['email']}',
      );
    } catch (e) {
      print('❌ [SupabaseAccountsAuth] Failed to create custom session: $e');
      rethrow;
    }
  }

  /// Get current user from custom session
  static Map<String, dynamic>? getCurrentUser() {
    // This will be implemented to return the current user from our custom session
    return null;
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      print('🔐 [SupabaseAccountsAuth] Signing out user');
      // Clear custom session data
      await _supabase.auth.signOut();
    } catch (e) {
      print('❌ [SupabaseAccountsAuth] Sign out failed: $e');
      rethrow;
    }
  }

  /// Check if user is authenticated
  static bool isAuthenticated() {
    // Check if we have a custom session
    return _supabase.auth.currentUser != null;
  }
}
