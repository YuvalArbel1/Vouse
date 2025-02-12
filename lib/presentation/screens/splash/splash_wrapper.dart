import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/entities/user_entity.dart';
import 'package:vouse_flutter/domain/usecases/home/get_user_usecase.dart';
import 'package:vouse_flutter/presentation/providers/home/local_user_providers.dart';

// Screens
import 'package:vouse_flutter/presentation/screens/auth/signin.dart';
import 'package:vouse_flutter/presentation/screens/auth/verification_pending_screen.dart';
import 'package:vouse_flutter/presentation/screens/home/edit_profile_screen.dart';
import 'package:vouse_flutter/presentation/screens/home/home_screen.dart';
import 'package:vouse_flutter/presentation/screens/splash/splash_screen.dart';

class SplashWrapper extends ConsumerStatefulWidget {
  const SplashWrapper({super.key});

  @override
  SplashWrapperState createState() => SplashWrapperState();
}

class SplashWrapperState extends ConsumerState<SplashWrapper> {

  @override
  void initState() {
    super.initState();
    // Instead of calling _initFlow() directly, we schedule it
    // AFTER the first frame is rendered to avoid the
    // "navigator is locked" issue.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFlow();
    });
  }

  /// The main flow:
  /// 1) Check currentUser from FirebaseAuth
  /// 2) If null => SignIn
  /// 3) If email not verified => VerificationPendingScreen
  /// 4) Else check local DB for user => EditProfileScreen or HomeScreen
  Future<void> _initFlow() async {
    // (Optional) small delay so the user sees the splash
    await Future.delayed(const Duration(seconds: 2));

    // Grab the current user
    final user = FirebaseAuth.instance.currentUser;

    // 1) If no user => go SignIn
    if (user == null) {
      _navigateTo(const SignInScreen());
      return;
    }

    // 2) If user is logged in but not verified => VerificationPendingScreen
    await user.reload();
    if (!user.emailVerified) {
      _navigateTo(const VerificationPendingScreen());
      return;
    }

    // 3) If user is verified => check local DB
    final getUserUC = ref.read(getUserUseCaseProvider);
    final result = await getUserUC.call(params: GetUserParams(user.uid));

    if (result is DataSuccess<UserEntity?>) {
      final localUser = result.data; // might be null
      if (localUser == null) {
        // Not found => EditProfile
        _navigateTo(const EditProfileScreen());
      } else {
        // Found => Home
        _navigateTo(const HomeScreen());
      }
    } else if (result is DataFailed<UserEntity?>) {
      // You can show an error or just sign out
      final errorMsg = result.error?.error ?? 'Unknown DB error';
      debugPrint('Error loading local profile: $errorMsg');
      _navigateTo(const SignInScreen());
    } else {
      // fallback
      _navigateTo(const SignInScreen());
    }
  }

  /// Safely navigate to [screen] if still mounted.
  void _navigateTo(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    // While the checks are going on, display the splash screen
    // with your logo & purple background.
    return const SplashScreen();
  }
}
