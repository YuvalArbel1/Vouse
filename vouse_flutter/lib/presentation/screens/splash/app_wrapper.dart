// lib/presentation/screens/splash/app_wrapper.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// Providers
import '../../../core/util/ui_settings.dart';
import '../../providers/auth/firebase/auth_state_provider.dart';
import '../../providers/local_db/database_provider.dart';
import '../../providers/navigation/navigation_service.dart';
import '../../providers/user/user_profile_provider.dart';
import '../../providers/local_db/local_user_providers.dart';
import '../../providers/server/server_sync_provider.dart'; // Add this import

// Domain entities and use cases
import 'package:vouse_flutter/domain/usecases/home/get_user_usecase.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';

// Widgets
import '../../widgets/common/loading/full_screen_loading.dart';

/// A sophisticated wrapper that manages the entire app's navigation flow
/// based on authentication, database initialization, and user profile status.
class AppWrapper extends ConsumerStatefulWidget {
  const AppWrapper({super.key});

  @override
  ConsumerState<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends ConsumerState<AppWrapper> {
  bool _isInitializingDatabase = true;
  bool _isAuthenticating = true;
  bool _isCheckingProfile = true;
  bool _isSynchronizingServer = true; // Added flag for server sync

  @override
  void initState() {
    super.initState();

    UiSettings.hideSystemNavBar();

    // Ensure splash screen is preserved during critical initializations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAppFlow();
    });
  }

  /// Comprehensive initialization of app flow
  Future<void> _initializeAppFlow() async {
    try {
      // First, ensure database is initialized
      await ref.read(localDatabaseProvider.future);

      // Set initial states
      if (mounted) {
        setState(() {
          _isInitializingDatabase = false;
        });
      }

      // Wait for auth state to stabilize
      await _waitForAuthState();
    } catch (e) {
      if (kDebugMode) {
        print('Initialization Error: $e');
      }

      // In case of critical error, remove splash and show error
      if (mounted) {
        FlutterNativeSplash.remove();
        setState(() {
          _isInitializingDatabase = false;
          _isAuthenticating = false;
          _isCheckingProfile = false;
          _isSynchronizingServer = false;
        });
      }
    }
  }

  /// Wait for and handle authentication state
  Future<void> _waitForAuthState() async {
    // Use the stream provider to listen to auth changes
    final authState = await ref.read(authStateProvider.future);

    if (mounted) {
      setState(() {
        _isAuthenticating = false;
      });

      // Determine navigation based on auth state
      switch (authState) {
        case AuthState.unauthenticated:
          _navigateToSignIn();
          break;
        case AuthState.unverified:
          _navigateToVerificationPending();
          break;
        case AuthState.authenticated:
          await _handleAuthenticatedUser();
          break;
        case AuthState.initial:
        // Unexpected state, default to sign-in
          _navigateToSignIn();
          break;
      }
    }
  }

  /// Handle authenticated user navigation with robust profile checking
  Future<void> _handleAuthenticatedUser() async {
    setState(() {
      _isCheckingProfile = true;
    });

    try {
      final userId = ref.read(currentUserIdProvider);

      if (userId == null) {
        _navigateToSignIn();
        return;
      }

      // Directly use getUserUseCase for more reliable profile checking
      final getUserUseCase = ref.read(getUserUseCaseProvider);
      final result = await getUserUseCase.call(params: GetUserParams(userId));

      // Based on the result, determine if we need profile creation
      if (result is DataSuccess && result.data != null) {
        // Profile exists, update the provider and synchronize with server
        ref.read(userProfileProvider.notifier).loadUserProfile();

        // Synchronize with server before navigating
        setState(() {
          _isSynchronizingServer = true;
        });

        try {
          // Trigger synchronization with server
          await ref.read(serverSyncProvider.notifier).synchronizePosts();
        } catch (e) {
          debugPrint('Server synchronization error: $e');
          // Continue even if sync fails - don't block app startup
        } finally {
          setState(() {
            _isSynchronizingServer = false;
          });
        }

        _navigateToMainApp();
      } else {
        // No profile exists, go to profile creation
        _navigateToEditProfile();
      }
    } catch (e) {
      if (kDebugMode) {
        print('User Profile Check Error: $e');
      }

      // On error, default to sign-in
      _navigateToSignIn();
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingProfile = false;
          _isSynchronizingServer = false;
        });
      }
    }
  }

  /// Navigation methods with proper context and stack clearing
  void _navigateToSignIn() {
    FlutterNativeSplash.remove();
    ref
        .read(navigationServiceProvider)
        .navigateToSignIn(context, clearStack: true);
  }

  void _navigateToVerificationPending() {
    FlutterNativeSplash.remove();
    ref
        .read(navigationServiceProvider)
        .navigateToVerificationPending(context, clearStack: true);
  }

  void _navigateToEditProfile() {
    FlutterNativeSplash.remove();
    ref
        .read(navigationServiceProvider)
        .navigateToEditProfile(context, clearStack: true);
  }

  void _navigateToMainApp() {
    FlutterNativeSplash.remove();
    ref
        .read(navigationServiceProvider)
        .navigateToAppNavigator(context, clearStack: true);
  }

  @override
  Widget build(BuildContext context) {
    // Show loading during critical initialization stages
    if (_isInitializingDatabase || _isAuthenticating || _isCheckingProfile || _isSynchronizingServer) {
      // Custom loading message based on current step
      String loadingMessage = "Preparing your Vouse experience...";

      if (_isSynchronizingServer) {
        loadingMessage = "Syncing your posted content...";
      } else if (_isCheckingProfile) {
        loadingMessage = "Loading your profile...";
      }

      return Scaffold(
        body: FullScreenLoading(
          message: loadingMessage,
        ),
      );
    }

    // If all checks pass, render an empty scaffold (transient state)
    return const Scaffold(body: SizedBox.shrink());
  }
}