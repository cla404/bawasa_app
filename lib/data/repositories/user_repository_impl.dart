import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_config.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';

class SupabaseUserRepository implements UserRepository {
  final SupabaseClient _supabase = SupabaseConfig.client;

  @override
  Future<UserProfile?> createUserProfile({
    required String authUserId,
    required String email,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    print('SupabaseUserRepository: Creating user profile for $email');
    print('SupabaseUserRepository: Auth User ID: $authUserId');

    // Try with 'pending' first, fallback to 'consumer' if constraint error
    // TODO: Remove this fallback after applying the database migration
    final accountTypes = ['pending', 'consumer'];

    for (final accountType in accountTypes) {
      try {
        final userData = {
          'auth_user_id': authUserId,
          'email': email,
          'full_name': fullName,
          'phone': phone,
          'avatar_url': avatarUrl,
          'account_type': accountType,
          'is_active': true,
          'last_login_at': DateTime.now().toIso8601String(),
        };

        print(
          'SupabaseUserRepository: Trying to insert with account_type: $accountType',
        );
        print('SupabaseUserRepository: User data to insert: $userData');

        final response = await _supabase
            .from('users')
            .insert(userData)
            .select()
            .single();

        print(
          'SupabaseUserRepository: User profile created successfully with account_type: $accountType',
        );
        return UserProfile.fromJson(response);
      } catch (e) {
        print(
          'SupabaseUserRepository: Error creating user profile with $accountType: $e',
        );
        print('SupabaseUserRepository: Error type: ${e.runtimeType}');

        if (e.toString().contains('constraint') && accountType == 'pending') {
          print(
            'SupabaseUserRepository: Pending account_type not allowed, trying consumer',
          );
          print('SupabaseUserRepository: Full error details: $e');
          continue; // Try next account type
        } else {
          print(
            'SupabaseUserRepository: Fatal error, cannot create user profile',
          );
          return null;
        }
      }
    }

    print(
      'SupabaseUserRepository: Failed to create user profile with any account type',
    );
    return null;
  }

  @override
  Future<UserProfile?> getUserProfile(String authUserId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('auth_user_id', authUserId)
          .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  @override
  Future<UserProfile?> updateUserProfile(UserProfile userProfile) async {
    try {
      final response = await _supabase
          .from('users')
          .update({
            'email': userProfile.email,
            'full_name': userProfile.fullName,
            'phone': userProfile.phone,
            'avatar_url': userProfile.avatarUrl,
            'account_type': userProfile.accountType.name,
            'is_active': userProfile.isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('auth_user_id', userProfile.authUserId)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error updating user profile: $e');
      return null;
    }
  }

  @override
  Future<void> updateLastLogin(String authUserId) async {
    try {
      await _supabase
          .from('users')
          .update({
            'last_login_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('auth_user_id', authUserId);
    } catch (e) {
      print('Error updating last login: $e');
    }
  }

  @override
  Future<bool> userProfileExists(String authUserId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('auth_user_id', authUserId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking if user profile exists: $e');
      return false;
    }
  }
}
