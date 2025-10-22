import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/supabase_config.dart';
import 'core/injection/injection_container.dart';
import 'data/repositories/supabase_accounts_auth_repository_impl.dart';
import 'presentation/pages/auth_wrapper.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/meter_reading_bloc.dart';
import 'presentation/bloc/consumer_bloc.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  await init();

  // Initialize Supabase accounts auth repository
  final supabaseAccountsAuthRepo = sl<SupabaseAccountsAuthRepositoryImpl>();
  await supabaseAccountsAuthRepo.loadUserFromStorage();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (context) => sl<AuthBloc>()),
        BlocProvider<MeterReadingBloc>(
          create: (context) => sl<MeterReadingBloc>(),
        ),
        BlocProvider<ConsumerBloc>(create: (context) => sl<ConsumerBloc>()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'BAWASA Management System',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color.fromARGB(255, 26, 125, 206),
          ),
        ),
        home: const DeepLinkHandler(child: AuthWrapper()),
      ),
    );
  }
}

class DeepLinkHandler extends StatefulWidget {
  final Widget child;

  const DeepLinkHandler({super.key, required this.child});

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() {
    // Handle app links when the app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        print('Deep link error: $err');
      },
    );

    // Handle app links when the app is launched from a link
    _appLinks.getInitialLink().then((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });
  }

  void _handleDeepLink(Uri uri) {
    print('Deep link received: $uri');

    // Check if this is a Supabase auth callback
    if (uri.toString().contains('access_token') ||
        uri.toString().contains('refresh_token') ||
        uri.toString().contains('type=recovery') ||
        uri.toString().contains('type=signup')) {
      // Handle email verification without auto-login
      if (mounted) {
        _handleEmailVerification();
      }
    }
  }

  void _handleEmailVerification() async {
    print('Handling email verification - preventing auto-login');

    // Wait a moment for Supabase to complete the auto-login
    await Future.delayed(const Duration(milliseconds: 1000));

    // Check if user is currently authenticated (from auto-login)
    final currentUser = SupabaseConfig.client.auth.currentUser;
    if (currentUser != null) {
      print('User is auto-logged in after email verification');
      print('User email: ${currentUser.email}');
      print('User ID: ${currentUser.id}');
      print('User confirmed: ${currentUser.emailConfirmedAt != null}');
    } else {
      print('No user found during email verification');
    }

    // Sign out the user to prevent auto-login
    try {
      await SupabaseConfig.client.auth.signOut();
      print('User signed out after email verification');
    } catch (e) {
      print('Error signing out after email verification: $e');
    }

    // Show success message asking user to sign in
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email confirmed successfully! Please sign in to continue.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
