import '../entities/user.dart';
import '../entities/auth_credentials.dart';
import '../entities/auth_result.dart';

abstract class AuthRepository {
  Future<AuthResult> signIn(AuthCredentials credentials);
  Future<AuthResult> signUp(SignUpCredentials credentials);
  Future<AuthResult> signOut();
  Future<AuthResult> resetPassword(String email);
  Future<AuthResult> resendConfirmationEmail(String email);
  Future<AuthResult> updateProfile(UpdateProfileParams params);
  User? getCurrentUser();
  Stream<User?> get authStateChanges;
}
