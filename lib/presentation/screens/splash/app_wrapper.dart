// lib/presentation/screens/splash/app_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// Import the auth state provider
import 'package:vouse_flutter/presentation/providers/user/user_profile_provider.dart';

import '../../providers/auth/firebase/auth_state_provider.dart';
import '../../providers/local_db/database_provider.dart';
import '../../widgets/common/loading/full_screen_loading.dart';
import '../../widgets/navigation/navigation_service.dart';

/// A wrapper that directs the user flow based on authentication and local DB status.
class AppWrapper extends ConsumerStatefulWidget {
  const AppWrapper({super.key});

  @override
  ConsumerState<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends ConsumerState<AppWrapper> {
  bool _didInitFlow = false;
  bool _isInitializing = true;

  // Constants for delay durations to avoid magic numbers.
  static const Duration _shortDelay = Duration(milliseconds: 1000);
  static const Duration _homeDelay = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    // DO NOT remove splash screen yet - wait for DB to initialize

    // Start the DB initialization process
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDatabaseInit();
    });
  }

  // First, ensure the database is initialized
  Future<void> _startDatabaseInit() async {
    try {
      // This will trigger the database initialization
      await ref.read(localDatabaseProvider.future);

      // Once DB is ready, remove splash screen and continue flow
      FlutterNativeSplash.remove();

      // Now proceed with the rest of initialization
      _safeInitFlow();
    } catch (e) {
      // If DB initialization fails, still remove splash but show error
      FlutterNativeSplash.remove();
      print("Database initialization error: $e");
      setState(() => _isInitializing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Database state should already be initiated from _startDatabaseInit
    final dbState = ref.watch(localDatabaseProvider);

    // If database is in error state, show error
    if (dbState is AsyncError) {
      return Scaffold(
        body: Center(child: Text('Database initialization error: ${dbState.error}')),
      );
    }

    // If still initializing overall flow, show loading
    if (_isInitializing) {
      return const Scaffold(
        body: FullScreenLoading(message: "Preparing your experience..."),
      );
    }

    // Check auth state only when database is ready
    final authStateAsync = ref.watch(authStateProvider);

    return authStateAsync.when(
      data: (authState) {
        // Render an empty scaffold during routing
        return const Scaffold(body: SizedBox.shrink());
      },
      loading: () => const Scaffold(
        body: FullScreenLoading(message: "Checking login status..."),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Authentication error: $err')),
      ),
    );
  }

  /// Safely initializes flow with proper error handling
  Future<void> _safeInitFlow() async {
    setState(() => _isInitializing = true);

    try {
      await _initFlow();
    } catch (e) {
      print("Error during initialization: $e");
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  /// Initializes the user flow based on authentication and local user profile.
  Future<void> _initFlow() async {
    if (!mounted) return;

    _didInitFlow = true;
    final navigationService = ref.read(navigationServiceProvider);

    // Get current auth state
    final authStateValue = ref.read(authStateProvider).value;

    // If state isn't determined yet, wait
    if (authStateValue == null) {
      return;
    }

    // Handle different auth states
    switch (authStateValue) {
      case AuthState.unauthenticated:
        await Future.delayed(_shortDelay);
        if (!mounted) return;
        navigationService.navigateToSignIn(context, clearStack: true);
        break;

      case AuthState.unverified:
        await Future.delayed(_shortDelay);
        if (!mounted) return;
        navigationService.navigateToVerificationPending(context, clearStack: true);
        break;

      case AuthState.authenticated:
      // Now safely load user profile
        try {
          await ref.read(userProfileProvider.notifier).loadUserProfile();
        } catch (e) {
          print("Error loading user profile: $e");
        }

        // Check if profile exists
        final userProfile = ref.read(userProfileProvider).user;
        await Future.delayed(_homeDelay);
        if (!mounted) return;

        if (userProfile == null) {
          // No profile - go to profile creation
          navigationService.navigateToEditProfile(context, isEditProfile: false, clearStack: true);
        } else {
          // Has profile - go to main app
          navigationService.navigateToAppNavigator(context, clearStack: true);
        }
        break;

      case AuthState.initial:
      // Still initializing, wait for a definitive state
        break;
    }
  }
}