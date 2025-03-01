// lib/presentation/screens/auth/verification_pending_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/presentation/providers/auth/firebase/firebase_auth_notifier.dart';
import 'package:vouse_flutter/presentation/screens/home/edit_profile_screen.dart';
import '../../../core/util/colors.dart';
import '../../../core/util/common.dart';
import '../../widgets/navigation/navigation_service.dart';

/// A screen prompting the user to verify their email.
/// Provides options to check verification status or resend the verification email.
class VerificationPendingScreen extends ConsumerStatefulWidget {
  const VerificationPendingScreen({super.key});

  @override
  ConsumerState<VerificationPendingScreen> createState() =>
      _VerificationPendingScreenState();
}

class _VerificationPendingScreenState
    extends ConsumerState<VerificationPendingScreen> {
  /// Indicates whether we show a processing spinner.
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _removeSplashAfterFirstFrame();
  }

  /// Removes the native splash after the first frame is drawn.
  void _removeSplashAfterFirstFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  /// Checks if the user's email is verified by calling [checkEmailVerified].
  /// If verified, navigates to [EditProfileScreen].
  /// Otherwise, shows a toast urging the user to retry or resend the email.
  Future<void> _checkVerification() async {
    setState(() => _checking = true);

    final isVerified = await ref
        .read(firebaseAuthNotifierProvider.notifier)
        .checkEmailVerified();

    // If the widget got unmounted before we proceed, bail out to avoid context usage.
    if (!mounted) return;

    setState(() => _checking = false);

    if (isVerified) {
      toast("Email verified! Welcome to the app.");
      ref.read(navigationServiceProvider).navigateToEditProfile(
          context,
          isEditProfile: false,
          clearStack: true
      );
    } else {
      toast("Still not verified. Try again soon or resend the email.");
    }
  }

  /// Resends the verification email via [sendVerificationEmail].
  /// If it fails, shows a toast with an error; otherwise, instructs the user to check their inbox.
  Future<void> _resendVerification() async {
    await ref
        .read(firebaseAuthNotifierProvider.notifier)
        .sendVerificationEmail();

    // Check if widget is unmounted
    if (!mounted) return;

    final state = ref.read(firebaseAuthNotifierProvider);
    if (state is DataFailed<void>) {
      final error = state.error?.error ?? 'Error';
      toast("Resend failed: $error");
    } else {
      toast("Verification email resent. Check your inbox!");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Background + layout
          Container(
            width: screenWidth,
            height: screenHeight,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/vouse_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Verify Your Email",
                      style: boldTextStyle(size: 24, color: black)),
                  const SizedBox(height: 16),
                  Text(
                    "We have sent a verification link to your email.\n"
                    "Please click it before continuing.",
                    style: primaryTextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Column(
                    children: [
                      AppButton(
                        text: "Check Verification",
                        color: vPrimaryColor,
                        textColor: Colors.white,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        onTap: _checkVerification,
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        text: "Resend Email",
                        color: vPrimaryColor,
                        textColor: Colors.white,
                        shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        onTap: _resendVerification,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Spinner overlay if checking
          BlockingSpinnerOverlay(isVisible: _checking),
        ],
      ),
    );
  }
}
