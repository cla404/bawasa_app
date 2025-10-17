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
        // Only create/update user profile for confirmed users
        if (user.emailConfirmedAt != null) {
          try {
            print('AuthBloc: Creating/updating user profile for ${user.email}');
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
            } else {
              print(
                'AuthBloc: User profile creation failed, but continuing with sign in',
              );
            }
          } catch (e) {
            print('AuthBloc: Error creating/updating user profile: $e');
            // Don't fail the sign-in if profile creation fails
          }
        } else {
          print(
            'AuthBloc: User email not confirmed yet, skipping profile creation',
          );
        }

        print('AuthBloc: Emitting AuthAuthenticated state');
        emit(AuthAuthenticated(user));
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
    emit(AuthLoading());

    final result = await _signOutUseCase();

    if (result.isSuccess) {
      emit(AuthUnauthenticated());
    } else {
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

  void _onAuthStateChanged(AuthStateChanged event, Emitter<AuthState> emit) {
    print(
      'AuthBloc: Handling auth state change - User: ${event.user?.email ?? 'null'}',
    );
    if (event.user != null) {
      // Only create/update user profile for confirmed users
      // Skip profile creation for unconfirmed users (e.g., during sign-up before email confirmation)
      if (event.user!.emailConfirmedAt != null) {
        print('AuthBloc: User email confirmed, creating/updating profile');
        _createUserProfileUseCase(
              CreateUserProfileParams(
                authUserId: event.user!.id,
                email: event.user!.email,
                fullName: event.user!.fullName,
                phone: event.user!.phone,
                avatarUrl: event.user!.avatarUrl,
              ),
            )
            .then((profile) {
              if (profile != null) {
                print(
                  'AuthBloc: User profile created/updated successfully on auth state change',
                );
              } else {
                print(
                  'AuthBloc: User profile creation failed on auth state change, but continuing with authentication',
                );
              }
            })
            .catchError((e) {
              print(
                'AuthBloc: Error creating/updating user profile on auth state change: $e',
              );
              // Don't fail authentication if profile creation fails
            });
      } else {
        print(
          'AuthBloc: User email not confirmed yet, skipping profile creation',
        );
      }

      emit(AuthAuthenticated(event.user!));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
