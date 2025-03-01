// lib/presentation/screens/splash/app_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import the auth state provider
import 'package:vouse_flutter/presentation/providers/user/user_profile_provider.dart';

import '../../providers/auth/firebase/auth_state_provider.dart';
import '../../providers/local_db/database_provider.dart';
import '../../widgets/common/loading/full_screen_loading.dart';
import '../../widgets/navigation/navigation_service.dart';

/// A wrapper that directs the user flow based on authentication and local DB status.
///
/// The flow is:
/// 1. If no user is signed in, navigate to [SignInScreen].
/// 2. If the user is not verified, navigate to [VerificationPendingScreen].
/// 3. If the user is verified, check the local DB:
///    - If no profile exists, navigate to [EditProfileScreen].
///    - Otherwise, navigate to [AppNavigator] which handles the main app navigation.
class AppWrapper extends ConsumerStatefulWidget {
  const AppWrapper({super.key});

  @override
  ConsumerState<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends ConsumerState<AppWrapper> {
  bool _didInitFlow = false;

  // Constants for delay durations to avoid magic numbers.
  static const Duration _shortDelay = Duration(milliseconds: 1000);
  static const Duration _homeDelay = Duration(seconds: 2);

  @override
  Widget build(BuildContext context) {
    // Watch the auth state provider
    final authStateAsync = ref.watch(authStateProvider);

    // Watch database initialization state (from the original provider)
    final dbAsyncValue = ref.watch(localDatabaseProvider);

    // Render different UI based on the DB and auth state
    return dbAsyncValue.when(
      data: (db) {
        // Run the initialization flow only once when DB is ready
        if (!_didInitFlow) {
          _didInitFlow = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _initFlow());
        }

        // Handle auth state changes
        return authStateAsync.when(
          data: (authState) {
            // Show a loading indicator while determining the right screen
            if (!_didInitFlow) {
              return const Scaffold(
                body: FullScreenLoading(message: "Preparing your experience..."),
              );
            }

            // Render an empty scaffold during routing (handled in _initFlow)
            return const Scaffold(body: SizedBox.shrink());
          },
          loading: () => const Scaffold(
            body: FullScreenLoading(message: "Checking login status..."),
          ),
          error: (err, stack) => Scaffold(
            body: Center(child: Text('Authentication error: $err')),
          ),
        );
      },
      loading: () => const Scaffold(
        body: FullScreenLoading(message: "Initializing..."),
      ),
      error: (err, stack) {
        // Display an error message if the DB fails to load
        return Scaffold(
          body: Center(child: Text('Database error: $err')),
        );
      },
    );
  }

  /// Initializes the user flow based on authentication and local user profile.
  ///
  /// This method dispatches to the appropriate screen based on auth state and user profile
  Future<void> _initFlow() async {
    if (!mounted) return;

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
      // Load user profile
        await ref.read(userProfileProvider.notifier).loadUserProfile();

        // Check if profile exists
        final userProfile = ref.read(userProfileProvider).user;
        await Future.delayed(_homeDelay);
        if (!mounted) return;

        if (userProfile == null) {
          // No profile - go to profile creation
          navigationService.navigateToEditProfile(context, clearStack: true);
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