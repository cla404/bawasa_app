import 'package:http/http.dart' as http;
import 'dart:convert';

class CustomAuthService {
  // Base URL for the web API
  static const String baseUrl =
      'http://192.168.100.170:3001'; // Update this with your actual web app URL

  // Custom sign in using accounts table via API
  static Future<Map<String, dynamic>> signInWithAccounts({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 [CustomAuthService] Attempting sign in for: $email');

      // Call the web API to verify credentials
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print(
        '🔐 [CustomAuthService] API response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ [CustomAuthService] Authentication successful');
        print('🔍 [CustomAuthService] User data: ${data['user']}');

        return {
          'success': true,
          'user': data['user'],
          'message': data['message'],
        };
      } else if (response.statusCode == 401) {
        print('❌ [CustomAuthService] Invalid credentials');
        return {'success': false, 'error': 'Invalid login credentials'};
      } else {
        final errorData = jsonDecode(response.body);
        print('❌ [CustomAuthService] API error: ${errorData['error']}');
        return {
          'success': false,
          'error': errorData['error'] ?? 'Authentication failed',
        };
      }
    } catch (e) {
      print('❌ [CustomAuthService] Sign in failed: $e');
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  // Get current user from custom session
  static Map<String, dynamic>? getCurrentUser() {
    // This would need to be implemented with proper session management
    // For now, we'll return null and handle this in the auth bloc
    return null;
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      // Clear any custom session data
      print('🔐 [CustomAuthService] Signing out user');
      // In a real implementation, you'd clear session storage here
    } catch (e) {
      print('❌ [CustomAuthService] Sign out failed: $e');
      rethrow;
    }
  }

  // Check if user is authenticated
  static bool isAuthenticated() {
    // This would need to be implemented with proper session management
    return false;
  }
}
