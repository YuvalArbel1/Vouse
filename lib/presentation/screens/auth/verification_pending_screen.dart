/// presentation/screens/auth/verification_pending_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/presentation/providers/auth/firebase_auth_notifier.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:vouse_flutter/presentation/screens/home/edit_profile_screen.dart';
import '../../../core/util/colors.dart';

class VerificationPendingScreen extends ConsumerStatefulWidget {
  const VerificationPendingScreen({super.key});

  @override
  ConsumerState<VerificationPendingScreen> createState() =>
      _VerificationPendingScreenState();
}

class _VerificationPendingScreenState
    extends ConsumerState<VerificationPendingScreen> {
  bool _checking = false;

  /// Poll or manually check once user taps "Check Verification."
  Future<void> _checkVerification() async {
    setState(() => _checking = true);

    // Returns bool, not bool?
    final bool isVerified = await ref
        .read(firebaseAuthNotifierProvider.notifier)
        .checkEmailVerified();

    setState(() => _checking = false);

    if (isVerified) {
      toast("Email verified! Welcome to the app.");
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
      );
      // Navigate to home or whatever
    } else {
      toast("Still not verified. Try again soon or resend the email.");
    }
  }

  /// Resend the verification email
  Future<void> _resendVerification() async {
    await ref
        .read(firebaseAuthNotifierProvider.notifier)
        .sendVerificationEmail();
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
    // Use nb_utils or normal Flutter for layout
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        // You can apply same background style as signIn / signUp
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
              if (_checking)
                const CircularProgressIndicator()
              else
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
                )
            ],
          ),
        ),
      ),
    );
  }
}
