import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/auth_usecases.dart';
import '../../../domain/usecases/user_usecases.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/entities/user.dart' as domain;
import '../../../core/injection/injection_container.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'dart:async';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final ResendConfirmationEmailUseCase _resendConfirmationEmailUseCase;
  final CreateUserProfileUseCase _createUserProfileUseCase;
  final AuthRepository _authRepository;
  StreamSubscription<domain.User?>? _authStateSubscription;
  final Set<String> _profileCreationInProgress = <String>{};

  AuthBloc({
    SignInUseCase? signInUseCase,
    SignUpUseCase? signUpUseCase,
    SignOutUseCase? signOutUseCase,
    ResetPasswordUseCase? resetPasswordUseCase,
    ResendConfirmationEmailUseCase? resendConfirmationEmailUseCase,
    CreateUserProfileUseCase? createUserProfileUseCase,
    AuthRepository? authRepository,
  }) : _signInUseCase = signInUseCase ?? sl<SignInUseCase>(),
       _signUpUseCase = signUpUseCase ?? sl<SignUpUseCase>(),
       _signOutUseCase = signOutUseCase ?? sl<SignOutUseCase>(),
       _resetPasswordUseCase =
           resetPasswordUseCase ?? sl<ResetPasswordUseCase>(),
       _resendConfirmationEmailUseCase =
           resendConfirmationEmailUseCase ??
           sl<ResendConfirmationEmailUseCase>(),
       _createUserProfileUseCase =
           createUserProfileUseCase ?? sl<CreateUserProfileUseCase>(),
       _authRepository = authRepository ?? sl<AuthRepository>(),
       super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<ResendConfirmationEmailRequested>(_onResendConfirmationEmailRequested);
    on<AuthErrorDismissed>(_onAuthErrorDismissed);
    on<AuthSuccessDismissed>(_onAuthSuccessDismissed);
    on<AuthStateChanged>(_onAuthStateChanged);

    // Initialize auth state listener
    _initAuthStateListener();
  }

  void _initAuthStateListener() {
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (user) {
        print('AuthBloc: Auth state changed - User: ${user?.email ?? 'null'}');
        if (user != null) {
          add(AuthStateChanged(user));
        } else {
          add(AuthStateChanged(null));
        }
      },
      onError: (error) {
        print('AuthBloc: Auth state change error: $error');
        add(AuthStateChanged(null));
      },
    );
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final user = _authRepository.getCurrentUser();
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    print('AuthBloc: Sign in requested for ${event.credentials.email}');

    final result = await _signInUseCase(event.credentials);
    print(
      'AuthBloc: Sign in result - Success: ${result.isSuccess}, Message: ${result.message}',
    );

    if (result.isSuccess) {
      // Try to get the user with a retry mechanism
      domain.User? user;
      int attempts = 0;
      const maxAttempts = 5;

      while (user == null && attempts < maxAttempts) {
        user = _authRepository.getCurrentUser();
        if (user == null) {
          await Future.delayed(const Duration(milliseconds: 200));
          attempts++;
        }
      }

      print(
        'AuthBloc: Current user retrieved after $attempts attempts: ${user?.email ?? 'null'}',
      );
      if (user != null) {
        // Check if this is a custom user (integer ID) or Supabase user (UUID)
        final isCustomUser = _isCustomUser(user.id);

        if (isCustomUser) {
          print('AuthBloc: Custom user detected, skipping profile creation');
          print('AuthBloc: Emitting AuthAuthenticated state for custom user');
          emit(AuthAuthenticated(user));
          print('AuthBloc: AuthAuthenticated state emitted successfully');
        } else {
          // Create/update user profile for Supabase users only (prevent duplicates)
          if (!_profileCreationInProgress.contains(user.id)) {
            _profileCreationInProgress.add(user.id);
            try {
              print(
                'AuthBloc: Creating/updating user profile for ${user.email}',
              );
              print(
                'AuthBloc: User details - ID: ${user.id}, Email: ${user.email}',
              );
              print('AuthBloc: User fullName: ${user.fullName}');
              print('AuthBloc: User phone: ${user.phone}');
              print('AuthBloc: User avatarUrl: ${user.avatarUrl}');

              final profile = await _createUserProfileUseCase(
                CreateUserProfileParams(
                  authUserId: user.id,
                  email: user.email,
                  fullName: user.fullName,
                  phone: user.phone,
                  avatarUrl: user.avatarUrl,
                ),
              );

              if (profile != null) {
                print('AuthBloc: User profile created/updated successfully');
                print('AuthBloc: Profile ID: ${profile.id}');
                print('AuthBloc: Profile account type: ${profile.accountType}');
                print('AuthBloc: Emitting AuthAuthenticated state');
                emit(AuthAuthenticated(user));
                print('AuthBloc: AuthAuthenticated state emitted successfully');
              } else {
                print('AuthBloc: User profile creation failed, emitting error');
                emit(
                  AuthError(
                    message: 'Failed to create user profile. Please try again.',
                  ),
                );
              }
            } catch (e) {
              print('AuthBloc: Error creating/updating user profile: $e');
              print('AuthBloc: Error type: ${e.runtimeType}');
              emit(
                AuthError(
                  message: 'Failed to create user profile: ${e.toString()}',
                ),
              );
            } finally {
              _profileCreationInProgress.remove(user.id);
            }
          } else {
            print(
              'AuthBloc: Profile creation already in progress for ${user.email}',
            );
            // Wait for profile creation to complete
            while (_profileCreationInProgress.contains(user.id)) {
              await Future.delayed(const Duration(milliseconds: 100));
            }
            print(
              'AuthBloc: Profile creation completed, emitting AuthAuthenticated',
            );
            print(
              'AuthBloc: User details - ID: ${user.id}, Email: ${user.email}',
            );
            emit(AuthAuthenticated(user));
            print('AuthBloc: AuthAuthenticated state emitted successfully');
          }
        }
      } else {
        print('AuthBloc: User is null after successful sign in and retries');
        emit(AuthError(message: 'Sign in successful but user not found'));
      }
    } else {
      print('AuthBloc: Sign in failed - ${result.message}');
      emit(
        AuthError(
          message: result.message ?? 'Sign in failed',
          errorCode: result.errorCode,
        ),
      );
    }
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    print('AuthBloc: Sign up requested for ${event.credentials.email}');

    final result = await _signUpUseCase(event.credentials);
    print(
      'AuthBloc: Sign up result - Success: ${result.isSuccess}, Message: ${result.message}',
    );

    if (result.isSuccess) {
      print('AuthBloc: Sign up successful, emitting AuthSuccess state');
      emit(AuthSuccess(result.message ?? 'Sign up successful'));
    } else {
      print('AuthBloc: Sign up failed - ${result.message}');
      emit(
        AuthError(
          message: result.message ?? 'Sign up failed',
          errorCode: result.errorCode,
        ),
      );
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('AuthBloc: Sign out requested');
    emit(AuthLoading());

    final result = await _signOutUseCase();
    print(
      'AuthBloc: Sign out result - Success: ${result.isSuccess}, Message: ${result.message}',
    );

    if (result.isSuccess) {
      print(
        'AuthBloc: Sign out successful, clearing profile creation tracking',
      );
      // Clear profile creation tracking
      _profileCreationInProgress.clear();
      print('AuthBloc: Emitting AuthUnauthenticated state');
      emit(AuthUnauthenticated());
      print('AuthBloc: AuthUnauthenticated state emitted successfully');
    } else {
      print('AuthBloc: Sign out failed - ${result.message}');
      emit(
        AuthError(
          message: result.message ?? 'Sign out failed',
          errorCode: result.errorCode,
        ),
      );
    }
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _resetPasswordUseCase(event.email);

    if (result.isSuccess) {
      emit(AuthSuccess(result.message ?? 'Password reset email sent'));
    } else {
      emit(
        AuthError(
          message: result.message ?? 'Failed to send password reset email',
          errorCode: result.errorCode,
        ),
      );
    }
  }

  Future<void> _onResendConfirmationEmailRequested(
    ResendConfirmationEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _resendConfirmationEmailUseCase(event.email);

    if (result.isSuccess) {
      emit(AuthSuccess(result.message ?? 'Confirmation email sent'));
    } else {
      emit(
        AuthError(
          message: result.message ?? 'Failed to send confirmation email',
          errorCode: result.errorCode,
        ),
      );
    }
  }

  void _onAuthErrorDismissed(
    AuthErrorDismissed event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthUnauthenticated());
  }

  void _onAuthSuccessDismissed(
    AuthSuccessDismissed event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthUnauthenticated());
  }

  Future<void> _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    print(
      'AuthBloc: Handling auth state change - User: ${event.user?.email ?? 'null'}',
    );
    if (event.user != null) {
      // Only emit AuthAuthenticated if we're not already in an authenticated state
      // This prevents duplicate emissions during sign-in process
      final currentState = state;
      if (currentState is! AuthAuthenticated ||
          currentState.user.id != event.user!.id) {
        print('AuthBloc: Emitting AuthAuthenticated from auth state change');
        print(
          'AuthBloc: Auth state change - User ID: ${event.user!.id}, Email: ${event.user!.email}',
        );

        // Check if this is a custom user (integer ID) or Supabase user (UUID)
        final isCustomUser = _isCustomUser(event.user!.id);

        if (isCustomUser) {
          print(
            'AuthBloc: Custom user detected in state change, skipping profile creation',
          );
          print('AuthBloc: Emitting AuthAuthenticated state for custom user');
          emit(AuthAuthenticated(event.user!));
          print('AuthBloc: AuthAuthenticated state emitted successfully');
        } else {
          // Create/update user profile for Supabase users only (prevent duplicates)
          if (!_profileCreationInProgress.contains(event.user!.id)) {
            _profileCreationInProgress.add(event.user!.id);
            try {
              print(
                'AuthBloc: Creating/updating user profile for ${event.user!.email}',
              );
              print(
                'AuthBloc: User details - ID: ${event.user!.id}, Email: ${event.user!.email}',
              );
              print('AuthBloc: User fullName: ${event.user!.fullName}');
              print('AuthBloc: User phone: ${event.user!.phone}');
              print('AuthBloc: User avatarUrl: ${event.user!.avatarUrl}');

              final profile = await _createUserProfileUseCase(
                CreateUserProfileParams(
                  authUserId: event.user!.id,
                  email: event.user!.email,
                  fullName: event.user!.fullName,
                  phone: event.user!.phone,
                  avatarUrl: event.user!.avatarUrl,
                ),
              );

              if (profile != null) {
                print('AuthBloc: User profile created/updated successfully');
                print('AuthBloc: Profile ID: ${profile.id}');
                print('AuthBloc: Profile account type: ${profile.accountType}');
                print('AuthBloc: Emitting AuthAuthenticated state');
                emit(AuthAuthenticated(event.user!));
                print('AuthBloc: AuthAuthenticated state emitted successfully');
              } else {
                print('AuthBloc: User profile creation failed, emitting error');
                emit(
                  AuthError(
                    message: 'Failed to create user profile. Please try again.',
                  ),
                );
              }
            } catch (e) {
              print('AuthBloc: Error creating/updating user profile: $e');
              print('AuthBloc: Error type: ${e.runtimeType}');
              emit(
                AuthError(
                  message: 'Failed to create user profile: ${e.toString()}',
                ),
              );
            } finally {
              _profileCreationInProgress.remove(event.user!.id);
            }
          } else {
            print(
              'AuthBloc: Profile creation already in progress for ${event.user!.email}',
            );
            // Wait for profile creation to complete
            while (_profileCreationInProgress.contains(event.user!.id)) {
              await Future.delayed(const Duration(milliseconds: 100));
            }
            print(
              'AuthBloc: Profile creation completed, emitting AuthAuthenticated',
            );
            emit(AuthAuthenticated(event.user!));
            print('AuthBloc: AuthAuthenticated state emitted successfully');
          }
        }
      } else {
        print(
          'AuthBloc: Already authenticated with same user, skipping emission',
        );
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }

  // Helper method to determine if a user is a custom user (integer ID) or Supabase user (UUID)
  bool _isCustomUser(String userId) {
    // Custom users have integer IDs, Supabase users have UUID strings
    // UUIDs contain hyphens, integers don't
    return !userId.contains('-') && int.tryParse(userId) != null;
  }
}
