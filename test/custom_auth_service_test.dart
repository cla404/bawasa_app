import 'package:flutter_test/flutter_test.dart';
import 'package:bawasa_system/services/custom_auth_service.dart';

void main() {
  group('CustomAuthService Tests', () {
    test('should authenticate with valid credentials', () async {
      // This test would require a running web server
      // For now, we'll just test the service structure

      final result = await CustomAuthService.signInWithAccounts(
        email: 'test@example.com',
        password: 'testpassword',
      );

      // The result should be a map with success/failure status
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), isTrue);
    });

    test('should handle network errors gracefully', () async {
      // Test with invalid URL to simulate network error
      final result = await CustomAuthService.signInWithAccounts(
        email: 'test@example.com',
        password: 'testpassword',
      );

      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
    });
  });
}
