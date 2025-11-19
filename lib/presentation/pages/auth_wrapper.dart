import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import 'sign_in.dart';
import 'consumer/consumer_account_main.dart';
import 'meter_reader/meter_reader_account_main.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Trigger initial auth check
    context.read<AuthBloc>().add(AuthCheckRequested());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('AuthWrapper: didChangeDependencies called');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        print('AuthWrapper: Listener - State changed to ${state.runtimeType}');
        print('AuthWrapper: Listener - Timestamp: ${DateTime.now()}');
        if (state is AuthAuthenticated) {
          print(
            'AuthWrapper: Listener - User authenticated: ${state.user.email}',
          );
          // Force immediate navigation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              print('AuthWrapper: Forcing navigation to main page');

              // Route based on user type - check user_type from CustomUser
              // Get the CustomUser to access userType field
              final customUser = context
                  .read<AuthBloc>()
                  .getCurrentCustomUser();
              final isMeterReader =
                  customUser?.userType == 'meter_reader';

              if (isMeterReader) {
                print('AuthWrapper: Routing meter reader to MeterReaderAccountMain');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MeterReaderAccountMain(key: ValueKey(state.user.id)),
                  ),
                );
              } else {
                print('AuthWrapper: Routing consumer to ConsumerAccountMain');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ConsumerAccountMain(key: ValueKey(state.user.id)),
                  ),
                );
              }
            }
          });
        } else if (state is AuthUnauthenticated) {
          print(
            'AuthWrapper: Listener - User unauthenticated, navigating to sign in',
          );
          // Force navigation back to sign in page
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              print('AuthWrapper: Forcing navigation to sign in page');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SignIn()),
              );
            }
          });
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          print('AuthWrapper: Builder - Current state is ${state.runtimeType}');
          print('AuthWrapper: Builder - State timestamp: ${DateTime.now()}');
          print('AuthWrapper: Builder - State details: $state');

          if (state is AuthLoading) {
            print('AuthWrapper: Showing loading screen');
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (state is AuthUnauthenticated) {
            print('AuthWrapper: User not authenticated, showing SignIn');
            return const SignIn();
          } else if (state is AuthError) {
            print('AuthWrapper: Auth error - ${state.message}');
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(AuthErrorDismissed());
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          } else {
            // For AuthAuthenticated, show loading while navigation happens
            print(
              'AuthWrapper: User authenticated, showing loading while navigating',
            );
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }
}
