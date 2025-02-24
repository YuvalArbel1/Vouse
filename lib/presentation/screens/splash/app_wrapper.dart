// lib/presentation/screens/splash/app_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/usecases/home/get_user_usecase.dart';

// Screens
import 'package:vouse_flutter/presentation/screens/auth/signin.dart';
import 'package:vouse_flutter/presentation/screens/auth/verification_pending_screen.dart';
import 'package:vouse_flutter/presentation/screens/home/edit_profile_screen.dart';
import 'package:vouse_flutter/presentation/screens/home/home_screen.dart';

import '../../../domain/entities/local_db/user_entity.dart';
import '../../providers/local_db/local_user_providers.dart';
import '../../providers/local_db/database_provider.dart';

/// A wrapper that directs the user flow based on authentication and local DB status.
///
/// The flow is:
/// 1. If no user is signed in, navigate to [SignInScreen].
/// 2. If the user is not verified, navigate to [VerificationPendingScreen].
/// 3. If the user is verified, check the local DB:
///    - If no profile exists, navigate to [EditProfileScreen].
///    - Otherwise, navigate to [HomeScreen].
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
    // Watch the local database provider.
    final dbAsyncValue = ref.watch(localDatabaseProvider);

    // Render different UI based on the DB state.
    return dbAsyncValue.when(
      data: (db) {
        // Run the initialization flow only once.
        if (!_didInitFlow) {
          _didInitFlow = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _initFlow());
        }

        // While the flow initializes, show an empty scaffold.
        return const Scaffold(body: SizedBox.shrink());
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) {
        // Display an error message if the DB fails to load.
        return Scaffold(
          body: Center(child: Text('DB error: $err')),
        );
      },
    );
  }

  /// Initializes the user flow based on authentication and local user profile.
  ///
  /// This method performs the following steps:
  /// 1. Checks for a signed-in user.
  /// 2. Verifies the user's email.
  /// 3. Retrieves the user profile from the local database.
  /// 4. Navigates to the appropriate screen.
  Future<void> _initFlow() async {
    // Ensure the widget is still mounted before proceeding.
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    // No user signed in: navigate to SignInScreen after a short delay.
    if (user == null) {
      await Future.delayed(_shortDelay);
      if (!mounted) return;
      _pushNext(const SignInScreen());
      return;
    }

    await user.reload();
    if (!mounted) return;

    // If the email is not verified: navigate to VerificationPendingScreen.
    if (!user.emailVerified) {
      await Future.delayed(_shortDelay);
      if (!mounted) return;
      _pushNext(const VerificationPendingScreen());
      return;
    }

    // User is verified; now check the local database for user profile.
    final getUserUC = ref.read(getUserUseCaseProvider);
    final result = await getUserUC.call(params: GetUserParams(user.uid));
    if (!mounted) return;

    if (result is DataSuccess<UserEntity?>) {
      final localUser = result.data;
      if (localUser == null) {
        _pushNext(const EditProfileScreen());
      } else {
        // Delay before navigating to HomeScreen to allow for transitions.
        await Future.delayed(_homeDelay);
        if (!mounted) return;
        _pushNext(const HomeScreen());
      }
    } else if (result is DataFailed<UserEntity?>) {
      // On DB error, fallback to SignInScreen.
      _pushNext(const SignInScreen());
    } else {
      // Fallback navigation with a short delay.
      await Future.delayed(_shortDelay);
      if (!mounted) return;
      _pushNext(const SignInScreen());
    }
  }

  /// Navigates to the next screen by replacing the current route.
  ///
  /// The navigation occurs only if the widget is still mounted.
  void _pushNext(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
