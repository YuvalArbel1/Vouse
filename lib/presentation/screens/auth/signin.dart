// lib/presentation/screens/auth/signin.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:nb_utils/nb_utils.dart';

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/presentation/providers/auth/firebase/firebase_auth_notifier.dart';
import 'package:vouse_flutter/presentation/screens/auth/verification_pending_screen.dart';
import 'package:vouse_flutter/presentation/screens/home/edit_profile_screen.dart';
import 'package:vouse_flutter/presentation/screens/home/home_screen.dart';
import 'package:vouse_flutter/domain/usecases/home/get_user_usecase.dart';

import '../../../core/util/colors.dart';
import '../../../core/util/common.dart';
import '../../../domain/entities/local_db/user_entity.dart';
import '../../providers/local_db/local_user_providers.dart';
import '../../widgets/auth/forgot_password_dialog.dart';
import 'signup.dart';

/// A screen that handles Firebase sign-in with form validation,
/// plus a "Sign in with Google" button.
///
/// Validates user input and, on success, calls [firebaseAuthNotifierProvider]
/// to complete sign-in. Depending on the result, navigates to [HomeScreen],
/// [VerificationPendingScreen], or shows an error.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  /// Controllers for email & password input fields.
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  /// FocusNodes for controlling text field focus.
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passWordFocusNode = FocusNode();

  /// Toggles whether the password is obscured in the UI.
  bool _obscurePassword = true;

  /// Form key to validate email/password fields.
  final _formKey = GlobalKey<FormState>();

  /// Indicates if we are currently processing (show a spinner).
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _removeSplashAfterFirstFrame();
  }

  /// Removes the native splash screen after the first frame has been drawn.
  void _removeSplashAfterFirstFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  /// Attempts to sign in with email/password after validating the form.
  ///
  /// 1) Validates the form.
  /// 2) Shows the loading spinner.
  /// 3) Calls [firebaseAuthNotifierProvider]'s signIn.
  /// 4) On success, navigates to [HomeScreen].
  /// 5) If the error is "EMAIL_NOT_VERIFIED", goes to [VerificationPendingScreen].
  /// 6) Otherwise, shows a toast with the error.
  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() => _isProcessing = true);

    try {
      // Trigger sign-in from the FirebaseAuthNotifier.
      await ref
          .read(firebaseAuthNotifierProvider.notifier)
          .signIn(email, password);

      // Check the latest state from the auth notifier.
      final authState = ref.read(firebaseAuthNotifierProvider);

      if (!mounted) return; // Avoid using context if widget is unmounted.

      if (authState is DataSuccess<void>) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else if (authState is DataFailed<void>) {
        final errorMsg = authState.error?.error ?? 'Unknown error';

        if (errorMsg == 'EMAIL_NOT_VERIFIED') {
          toast("Email is not verified. Please check your inbox.");
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (_) => const VerificationPendingScreen()),
          );
        } else {
          toast("Login failed: $errorMsg");
        }
      }
    } finally {
      // Hide spinner regardless of success or error.
      setState(() => _isProcessing = false);
    }
  }

  /// Called when the user taps "Sign in with Google".
  ///
  /// If sign-in is successful, checks local DB for user:
  ///  - If no user => go to [EditProfileScreen].
  ///  - Else => [HomeScreen].
  /// On failure, shows a toast with the error.
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isProcessing = true);

    try {
      // Sign in with Google via the auth notifier.
      await ref.read(firebaseAuthNotifierProvider.notifier).signInWithGoogle();

      final authState = ref.read(firebaseAuthNotifierProvider);
      if (!mounted) return;

      if (authState is DataSuccess<void>) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          toast("Google sign-in succeeded, but no Firebase user found.");
          return;
        }

        // Check if the user exists locally in our DB.
        final getUserUC = ref.read(getUserUseCaseProvider);
        final result =
            await getUserUC.call(params: GetUserParams(currentUser.uid));
        if (!mounted) return;

        if (result is DataSuccess<UserEntity?>) {
          final localUser = result.data;
          if (localUser == null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        } else {
          final error = (result as DataFailed?)?.error?.error ?? 'DB error';
          toast("Local DB check failed: $error");
        }
      } else if (authState is DataFailed<void>) {
        final errorMsg = authState.error?.error ?? 'Unknown error';
        toast("Google sign-in failed: $errorMsg");
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Background image + scrollable content
          Container(
            width: screenWidth,
            height: screenHeight,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/vouse_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 50),
                  // Title
                  Text("Log In", style: boldTextStyle(size: 24, color: black)),
                  // Main card + logo at top
                  Container(
                    margin: const EdgeInsets.all(16),
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[
                        // Card behind the logo
                        Container(
                          width: screenWidth,
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, bottom: 16),
                          margin: const EdgeInsets.only(top: 55.0),
                          decoration: boxDecorationWithShadow(
                            borderRadius: BorderRadius.circular(30),
                            backgroundColor: context.cardColor,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const SizedBox(height: 50),

                                // Email label + field
                                Text("Email", style: boldTextStyle(size: 14)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: emailController,
                                  focusNode: emailFocusNode,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: waInputDecoration(
                                    hint: 'Enter your email here',
                                    prefixIcon: Icons.email_outlined,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Email is required';
                                    }
                                    if (!value.trim().validateEmail()) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Password label + field
                                Text("Password",
                                    style: boldTextStyle(size: 14)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: passwordController,
                                  focusNode: passWordFocusNode,
                                  obscureText: _obscurePassword,
                                  keyboardType: TextInputType.text,
                                  decoration: waInputDecoration(
                                    hint: 'Enter your password here',
                                    prefixIcon: Icons.lock_outline,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: vPrimaryColor,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password is required';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Forgot password link
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (dialogCtx) =>
                                            const ForgotPasswordDialog(),
                                      );
                                    },
                                    child: Text("Forgot password?",
                                        style: primaryTextStyle()),
                                  ),
                                ),

                                const SizedBox(height: 30),

                                // Log in button
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: screenWidth * 0.1,
                                    right: screenWidth * 0.1,
                                  ),
                                  child: AppButton(
                                    text: "Log In",
                                    color: vPrimaryColor,
                                    textColor: Colors.white,
                                    shapeBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    width: screenWidth,
                                    onTap: _handleLogin,
                                  ),
                                ),

                                const SizedBox(height: 30),

                                // or divider
                                Center(
                                  child: SizedBox(
                                    width: 200,
                                    child: Row(
                                      children: [
                                        const Expanded(
                                            child: Divider(thickness: 2)),
                                        const SizedBox(width: 8),
                                        Text('or',
                                            style: boldTextStyle(
                                                size: 16, color: Colors.grey)),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                            child: Divider(thickness: 2)),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 30),

                                // Sign in with Google
                                Center(
                                  child: InkWell(
                                    onTap: _handleGoogleSignIn,
                                    child: Container(
                                      decoration:
                                          boxDecorationRoundedWithShadow(
                                        16,
                                        backgroundColor: context.cardColor,
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GoogleLogoWidget(size: 40),
                                          const SizedBox(width: 8),
                                          Text("Sign in with Google",
                                              style: boldTextStyle()),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 30),

                                // Register link
                                Center(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SignUpScreen(),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Don't have an account?",
                                          style: primaryTextStyle(
                                              color: Colors.grey),
                                        ),
                                        const SizedBox(width: 4),
                                        Text('Register here',
                                            style: boldTextStyle(color: black)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Circle logo on top of the card
                        Container(
                          alignment: Alignment.center,
                          height: 100,
                          width: 100,
                          decoration: boxDecorationRoundedWithShadow(
                            30,
                            backgroundColor: context.cardColor,
                          ),
                          child: Image.asset(
                            'assets/images/vouse_app_logo.png',
                            height: 60,
                            width: 60,
                            color: vPrimaryColor,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Overlays a blocking spinner if _isProcessing is true
          BlockingSpinnerOverlay(isVisible: _isProcessing),
        ],
      ),
    );
  }
}
