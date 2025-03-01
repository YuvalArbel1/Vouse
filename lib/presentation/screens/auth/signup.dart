// lib/presentation/screens/auth/signup.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:vouse_flutter/presentation/providers/auth/firebase/firebase_auth_notifier.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/presentation/screens/auth/verification_pending_screen.dart';
import '../../../core/util/colors.dart';
import '../../../core/util/common.dart';
import '../../widgets/navigation/navigation_service.dart';

/// A screen to register (sign up) a new user with Firebase.
/// Uses a [Form] for validation, plus the [firebaseAuthNotifierProvider] for sign-up logic.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  /// Controllers for email & password input fields.
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  /// Focus nodes for controlling field focus.
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passWordFocusNode = FocusNode();
  final FocusNode confirmPassWordFocusNode = FocusNode();

  /// Toggles for showing/hiding password text fields.
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  /// Form key for validation.
  final _formKey = GlobalKey<FormState>();

  /// Indicates whether we show a blocking spinner overlay.
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _removeSplashAfterFirstFrame();
  }

  /// Remove the native splash after the widget’s first frame.
  void _removeSplashAfterFirstFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  /// Handles registration after validating the form fields.
  ///
  /// 1) Validate input.
  /// 2) Show spinner.
  /// 3) Call signUp from [firebaseAuthNotifierProvider].
  /// 4) On [DataSuccess], go to [VerificationPendingScreen].
  /// 5) Otherwise, show an error toast.
  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() => _isProcessing = true);

    try {
      // Perform sign-up
      await ref
          .read(firebaseAuthNotifierProvider.notifier)
          .signUp(email, password);

      if (!mounted) return; // Avoid using context if unmounted

      // Check the updated auth state
      final authState = ref.read(firebaseAuthNotifierProvider);
      if (authState is DataSuccess<void>) {
        ref.read(navigationServiceProvider).navigateToVerificationPending(
              context,
              clearStack: true,
            );
      } else if (authState is DataFailed<void>) {
        final errorMsg = authState.error?.error ?? 'Unknown error';
        toast("Registration failed: $errorMsg");
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // We don't actually use authState in build, so no need to watch:
    // final authState = ref.watch(firebaseAuthNotifierProvider);

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Background image
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
                  Text("Register New Account",
                      style: boldTextStyle(size: 24, color: black)),
                  Container(
                    margin: const EdgeInsets.all(16),
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[
                        // Main card
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
                                const SizedBox(height: 16),

                                // Email
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

                                // Password
                                Text("Password",
                                    style: boldTextStyle(size: 14)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: passwordController,
                                  focusNode: passWordFocusNode,
                                  obscureText: _obscurePassword,
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
                                        setState(() => _obscurePassword =
                                            !_obscurePassword);
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password is required';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters long';
                                    }
                                    // Avoid redundant escapes for special chars
                                    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]')
                                        .hasMatch(value)) {
                                      return 'Password must contain at least one special character';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Confirm Password
                                Text("Confirm Password",
                                    style: boldTextStyle(size: 14)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: confirmPasswordController,
                                  focusNode: confirmPassWordFocusNode,
                                  obscureText: _obscureConfirmPassword,
                                  decoration: waInputDecoration(
                                    hint: 'Re-type password',
                                    prefixIcon: Icons.lock_outline,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: vPrimaryColor,
                                      ),
                                      onPressed: () {
                                        setState(() => _obscureConfirmPassword =
                                            !_obscureConfirmPassword);
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please confirm your password';
                                    }
                                    if (value != passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 30),

                                // Register button
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: screenWidth * 0.1,
                                    right: screenWidth * 0.1,
                                  ),
                                  child: AppButton(
                                    text: "Register Account",
                                    color: vPrimaryColor,
                                    textColor: Colors.white,
                                    shapeBorder: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    width: screenWidth,
                                    onTap: _handleRegister,
                                  ),
                                ),

                                const SizedBox(height: 30),

                                // "Already have an account?" link
                                Center(
                                  child: InkWell(
                                    onTap: () => Navigator.pop(context),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text('Already have an account?',
                                            style: primaryTextStyle(
                                                color: Colors.grey)),
                                        const SizedBox(width: 4),
                                        Text('Log In here',
                                            style: boldTextStyle(color: black)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Logo at the top
                        Container(
                          alignment: Alignment.center,
                          height: 100,
                          width: 100,
                          decoration: boxDecorationWithShadow(
                            borderRadius: BorderRadius.circular(30),
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

          // Spinner overlay if processing
          BlockingSpinnerOverlay(isVisible: _isProcessing),
        ],
      ),
    );
  }
}
