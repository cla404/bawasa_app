import 'package:flutter_test/flutter_test.dart';
import 'package:bawasa_system/domain/entities/custom_user.dart';

void main() {
  group('CustomUser Tests', () {
    test('should handle consumer_id as string', () {
      final map = {
        'id': 1,
        'email': 'test@example.com',
        'full_name': 'Test User',
        'phone': '1234567890',
        'full_address': 'Test Address',
        'consumer_id': '123', // String instead of int
        'water_meter_no': 'B-2024-001',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final user = CustomUser.fromMap(map);

      expect(user.consumerId, equals(123));
      expect(user.email, equals('test@example.com'));
      expect(user.fullName, equals('Test User'));
    });

    test('should handle consumer_id as int', () {
      final map = {
        'id': 1,
        'email': 'test@example.com',
        'full_name': 'Test User',
        'phone': '1234567890',
        'full_address': 'Test Address',
        'consumer_id': 456, // Int
        'water_meter_no': 'B-2024-001',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final user = CustomUser.fromMap(map);

      expect(user.consumerId, equals(456));
      expect(user.email, equals('test@example.com'));
    });

    test('should handle null consumer_id', () {
      final map = {
        'id': 1,
        'email': 'test@example.com',
        'full_name': 'Test User',
        'phone': '1234567890',
        'full_address': 'Test Address',
        'consumer_id': null, // Null
        'water_meter_no': 'B-2024-001',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final user = CustomUser.fromMap(map);

      expect(user.consumerId, equals(0));
      expect(user.email, equals('test@example.com'));
    });
  });
}
