import '../entities/user_profile.dart';
import '../repositories/user_repository.dart';
import '../../core/usecases/usecase.dart';

class CreateUserProfileUseCase
    implements UseCase<UserProfile?, CreateUserProfileParams> {
  final UserRepository repository;

  CreateUserProfileUseCase(this.repository);

  @override
  Future<UserProfile?> call(CreateUserProfileParams params) async {
    try {
      // Check if user profile already exists
      final exists = await repository.userProfileExists(params.authUserId);
      if (exists) {
        // Update last login time for existing users
        await repository.updateLastLogin(params.authUserId);
        return await repository.getUserProfile(params.authUserId);
      }

      // Create new user profile
      return await repository.createUserProfile(
        authUserId: params.authUserId,
        email: params.email,
        fullName: params.fullName,
        phone: params.phone,
        avatarUrl: params.avatarUrl,
      );
    } catch (e) {
      print('Error in CreateUserProfileUseCase: $e');
      return null;
    }
  }
}

class CreateUserProfileParams {
  final String authUserId;
  final String email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;

  CreateUserProfileParams({
    required this.authUserId,
    required this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
  });
}

class GetUserProfileUseCase implements UseCase<UserProfile?, String> {
  final UserRepository repository;

  GetUserProfileUseCase(this.repository);

  @override
  Future<UserProfile?> call(String authUserId) async {
    try {
      return await repository.getUserProfile(authUserId);
    } catch (e) {
      print('Error in GetUserProfileUseCase: $e');
      return null;
    }
  }
}

class UpdateUserProfileUseCase implements UseCase<UserProfile?, UserProfile> {
  final UserRepository repository;

  UpdateUserProfileUseCase(this.repository);

  @override
  Future<UserProfile?> call(UserProfile userProfile) async {
    try {
      return await repository.updateUserProfile(userProfile);
    } catch (e) {
      print('Error in UpdateUserProfileUseCase: $e');
      return null;
    }
  }
}
