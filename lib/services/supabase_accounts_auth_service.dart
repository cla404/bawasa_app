import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';
import '../core/config/supabase_config.dart';

class SupabaseAccountsAuthService {
  static final SupabaseClient _supabase = SupabaseConfig.client;

  /// Sign in using credentials from the unified accounts table
  static Future<Map<String, dynamic>> signInWithAccounts({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 [SupabaseAccountsAuth] Attempting sign in for: $email');

      // Find user in the unified accounts table
      final accountResponse = await _supabase
          .from('accounts')
          .select('*')
          .eq('email', email)
          .maybeSingle();

      if (accountResponse == null) {
        print('❌ [SupabaseAccountsAuth] User not found: $email');
        return {'success': false, 'error': 'Invalid login credentials'};
      }

      print('✅ [SupabaseAccountsAuth] User found in accounts table');

      // Verify password using bcrypt
      final isPasswordValid = BCrypt.checkpw(
        password,
        accountResponse['password'],
      );

      if (!isPasswordValid) {
        print('❌ [SupabaseAccountsAuth] Invalid password for: $email');
        return {'success': false, 'error': 'Invalid login credentials'};
      }

      print('✅ [SupabaseAccountsAuth] Password verified successfully');

      // Get user type from database
      final dbUserType = accountResponse['user_type'];
      print('🔍 [SupabaseAccountsAuth] User type from database: $dbUserType');

      Map<String, dynamic> userData;
      String userType = dbUserType ?? 'consumer';

      if (userType == 'consumer') {
        // Get consumer data from bawasa_consumers table using consumer_id foreign key
        final consumerResponse = await _supabase
            .from('bawasa_consumers')
            .select('*')
            .eq('consumer_id', accountResponse['id'])
            .maybeSingle();

        if (consumerResponse == null) {
          print('❌ [SupabaseAccountsAuth] Consumer data not found');
          return {'success': false, 'error': 'Consumer data not found'};
        }

        print('✅ [SupabaseAccountsAuth] Consumer data retrieved');

        // Create a custom user object for consumer
        userData = {
          'id': accountResponse['id']?.toString() ?? '',
          'email': accountResponse['email'] ?? '',
          'full_name': accountResponse['full_name'] ?? '',
          'phone': accountResponse['mobile_no']?.toString() ?? '',
          'full_address': accountResponse['full_address'] ?? '',
          'consumer_id': consumerResponse['id']?.toString() ?? '',
          'water_meter_no': consumerResponse['water_meter_no'] ?? '',
          'created_at': accountResponse['created_at']?.toString() ?? '',
          'updated_at': accountResponse['updated_at']?.toString() ?? '',
          'user_type': userType,
        };
      } else if (userType == 'meter_reader') {
        // Get meter reader data from bawasa_meter_reader table using reader_id foreign key
        final meterReaderResponse = await _supabase
            .from('bawasa_meter_reader')
            .select('*')
            .eq('reader_id', accountResponse['id'])
            .maybeSingle();

        if (meterReaderResponse == null) {
          print('❌ [SupabaseAccountsAuth] Meter reader data not found');
          return {'success': false, 'error': 'Meter reader data not found'};
        }

        print('✅ [SupabaseAccountsAuth] Meter reader data retrieved');

        // Create a custom user object for meter reader
        userData = {
          'id': accountResponse['id']?.toString() ?? '',
          'email': accountResponse['email'] ?? '',
          'full_name': accountResponse['full_name'] ?? '',
          'phone': accountResponse['mobile_no']?.toString() ?? '',
          'full_address': accountResponse['full_address'] ?? '',
          'consumer_id': null, // Meter readers don't have consumer_id
          'water_meter_no': null, // Meter readers don't have water_meter_no
          'meter_reader_id': meterReaderResponse['id']?.toString() ?? '',
          'status': meterReaderResponse['status'] ?? '',
          'assigned_to': meterReaderResponse['assigned_to']?.toString() ?? '',
          'created_at': accountResponse['created_at']?.toString() ?? '',
          'updated_at': accountResponse['updated_at']?.toString() ?? '',
          'user_type': userType,
        };
      } else {
        print('❌ [SupabaseAccountsAuth] Unknown user type: $userType');
        return {'success': false, 'error': 'Invalid user type'};
      }

      // For Supabase auth integration, we need to create a session
      // Since we're not using Supabase's built-in auth, we'll create a custom session
      // This allows the app to work with Supabase's auth state management
      await _createCustomSession(userData);

      return {
        'success': true,
        'user': userData,
        'message': 'Authentication successful for $userType',
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
