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

// We won't import your old SplashScreen widget, because we rely on the native splash now.

class AppWrapper extends ConsumerStatefulWidget {
  const AppWrapper({super.key});

  @override
  ConsumerState<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends ConsumerState<AppWrapper> {
  @override
  void initState() {
    super.initState();
    _initFlow();
  }

  Future<void> _initFlow() async {
    // Decide which screen we want to show next
    // 1) Check if user is null => SignIn
    // 2) If user is not verified => VerificationPending
    // 3) If verified => local DB => EditProfile or Home
    // Then push it with a delay.

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // No user => push SignIn after 1.5s
      await Future.delayed(const Duration(milliseconds: 1000));
      _pushNext(const SignInScreen());
      return;
    }

    await user.reload();
    if (!user.emailVerified) {
      // Not verified => push VerificationPending after 1.5s
      await Future.delayed(const Duration(milliseconds: 1000));
      _pushNext(const VerificationPendingScreen());
      return;
    }

    // User verified => check local DB
    final getUserUC = ref.read(getUserUseCaseProvider);
    final result = await getUserUC.call(params: GetUserParams(user.uid));

    if (result is DataSuccess<UserEntity?>) {
      final localUser = result.data;
      if (localUser == null) {
        _pushNext(const EditProfileScreen());
      } else {
        // Found => Home, 3s
        await Future.delayed(const Duration(seconds: 2));
        // TODO - push Home with localUser
        _pushNext(const HomeScreen());
      }
    } else if (result is DataFailed<UserEntity?>) {
      // DB error => fallback signIn
      _pushNext(const SignInScreen());
    } else {
      // fallback
      await Future.delayed(const Duration(milliseconds: 1000));
      _pushNext(const SignInScreen());
    }
  }

  void _pushNext(Widget screen) {
    // If we're still mounted, push the new screen
    if (!mounted) return;

    // No 'removeSplash' here. We'll do that in the next screen's initState.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The user never sees this widget, because the native splash is still preserved.
    // You can show a blank container or anything. It's behind the scenes.
    return const Scaffold(
      body: SizedBox.shrink(),
    );
  }
}
