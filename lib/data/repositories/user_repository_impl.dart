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
    try {
      final response = await _supabase
          .from('users')
          .insert({
            'auth_user_id': authUserId,
            'email': email,
            'full_name': fullName,
            'phone': phone,
            'avatar_url': avatarUrl,
            'account_type': 'consumer',
            'is_active': true,
            'last_login_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error creating user profile: $e');
      return null;
    }
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
