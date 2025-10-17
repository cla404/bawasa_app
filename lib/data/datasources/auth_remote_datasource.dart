import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/auth_credentials.dart';

class SupabaseAuthDataSource {
  final SupabaseClient _supabase;

  SupabaseAuthDataSource(this._supabase);

  Future<AuthResponse> signIn(AuthCredentials credentials) async {
    return await _supabase.auth.signInWithPassword(
      email: credentials.email,
      password: credentials.password,
    );
  }

  Future<AuthResponse> signUp(SignUpCredentials credentials) async {
    return await _supabase.auth.signUp(
      email: credentials.email,
      password: credentials.password,
      emailRedirectTo: 'bawasa://auth/callback',
      data: {
        if (credentials.fullName != null) 'full_name': credentials.fullName,
        if (credentials.phone != null) 'phone': credentials.phone,
      },
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> resendConfirmationEmail(String email) async {
    await _supabase.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: 'bawasa://auth/callback',
    );
  }

  Future<UserResponse> updateProfile(UpdateProfileParams params) async {
    return await _supabase.auth.updateUser(
      UserAttributes(
        data: {
          if (params.fullName != null) 'full_name': params.fullName,
          if (params.phone != null) 'phone': params.phone,
          if (params.avatarUrl != null) 'avatar_url': params.avatarUrl,
        },
      ),
    );
  }

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }
}
