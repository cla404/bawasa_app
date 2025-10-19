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
      print(
        'CreateUserProfileUseCase: Starting profile creation for ${params.email}',
      );

      // Check if user profile already exists
      final exists = await repository.userProfileExists(params.authUserId);
      print('CreateUserProfileUseCase: Profile exists: $exists');

      if (exists) {
        // Update last login time for existing users
        print(
          'CreateUserProfileUseCase: Updating last login for existing user',
        );
        await repository.updateLastLogin(params.authUserId);
        final profile = await repository.getUserProfile(params.authUserId);
        print(
          'CreateUserProfileUseCase: Retrieved existing profile: ${profile != null}',
        );
        return profile;
      }

      // Create new user profile
      print('CreateUserProfileUseCase: Creating new user profile');
      final profile = await repository.createUserProfile(
        authUserId: params.authUserId,
        email: params.email,
        fullName: params.fullName,
        phone: params.phone,
        avatarUrl: params.avatarUrl,
      );

      print(
        'CreateUserProfileUseCase: Profile creation result: ${profile != null}',
      );
      return profile;
    } catch (e) {
      print('CreateUserProfileUseCase: Error in profile creation: $e');
      print('CreateUserProfileUseCase: Error type: ${e.runtimeType}');
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
