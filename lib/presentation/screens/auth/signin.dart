import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:nb_utils/nb_utils.dart';

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/presentation/providers/auth/firebase_auth_notifier.dart';
import 'package:vouse_flutter/presentation/screens/auth/verification_pending_screen.dart';
import 'package:vouse_flutter/presentation/screens/home/edit_profile_screen.dart';
import 'package:vouse_flutter/presentation/screens/home/home_screen.dart';
import 'package:vouse_flutter/domain/usecases/home/get_user_usecase.dart';

import '../../../core/util/colors.dart';
import '../../../core/util/common.dart';
import '../../../domain/entities/locaal db/user_entity.dart';
import '../../providers/local_db/local_user_providers.dart';
import '../../widgets/auth/forgot_password_dialog.dart';
import 'signup.dart';

/// A screen that handles Firebase sign-in with form validation,
/// plus a "Sign in with Google" button.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  /// Controllers for email & password fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  /// FocusNodes for controlling focus
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passWordFocusNode = FocusNode();

  /// Toggles whether the password is obscured
  bool _obscurePassword = true;

  /// Key for validating the form fields
  final _formKey = GlobalKey<FormState>();

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  /// Remove the native splash after the first frame, so we don't see it forever
  Future<void> init() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  /// Tries signing in with email/password after validating the form.
  ///
  /// Steps:
  /// 1. Validate the form inputs.
  /// 2. Call [firebaseAuthNotifierProvider]'s [signIn].
  /// 3. If [DataSuccess], navigate to [HomeScreen].
  /// 4. If "EMAIL_NOT_VERIFIED", show toast + navigate to [VerificationPendingScreen].
  /// 5. Otherwise, show an error toast.
  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // 1) Show spinner
    setState(() => _isProcessing = true);

    try {
      await ref
          .read(firebaseAuthNotifierProvider.notifier)
          .signIn(email, password);

      final authState = ref.read(firebaseAuthNotifierProvider);
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
      // 2) Hide spinner
      setState(() => _isProcessing = false);
    }
  }

  /// Called when the user taps "Sign in with Google."
  /// 1) We trigger the signInWithGoogle use case.
  /// 2) If successful, we check local DB:
  ///    - If user not found => go to EditProfile
  ///    - If user found => go to Home
  /// 3) If failed => show error toast
  Future<void> _handleGoogleSignIn() async {
    // Also show spinner while signing in with Google
    setState(() => _isProcessing = true);

    try {
      await ref.read(firebaseAuthNotifierProvider.notifier).signInWithGoogle();

      final authState = ref.read(firebaseAuthNotifierProvider);
      if (authState is DataSuccess<void>) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          toast("Google sign-in succeeded, but no Firebase user found.");
          return;
        }

        final getUserUC = ref.read(getUserUseCaseProvider);
        final result =
            await getUserUC.call(params: GetUserParams(currentUser.uid));
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
    final authState = ref.watch(firebaseAuthNotifierProvider);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
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
                  Text("Log In", style: boldTextStyle(size: 24, color: black)),
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

                                // Log In button
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

                                // "or" divider
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

                                // "Sign in with Google"
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
                                                const SignUpScreen()),
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

                        // Logo at the top
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
          BlockingSpinnerOverlay(isVisible: _isProcessing),

        ],
      ),
    );
  }
}
