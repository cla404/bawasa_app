import '../entities/user_profile.dart';

abstract class UserRepository {
  /// Creates a new user profile in the users table
  Future<UserProfile?> createUserProfile({
    required String authUserId,
    required String email,
    String? fullName,
    String? phone,
    String? avatarUrl,
  });

  /// Gets user profile by auth user ID
  Future<UserProfile?> getUserProfile(String authUserId);

  /// Updates user profile
  Future<UserProfile?> updateUserProfile(UserProfile userProfile);

  /// Updates last login time for a user
  Future<void> updateLastLogin(String authUserId);

  /// Checks if user profile exists for the given auth user ID
  Future<bool> userProfileExists(String authUserId);
}
