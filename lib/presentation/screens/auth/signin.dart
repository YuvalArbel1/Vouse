import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/presentation/providers/auth/firebase_auth_notifier.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import '../../../core/util/colors.dart';
import '../../../core/util/common.dart';
import '../../widgets/auth/forgot_password_dialog.dart';
import 'signup.dart';

/// A screen that handles Firebase sign-in with form validation,
/// plus a "Sign in with Google" button (and no Facebook).
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  /// Controllers for email & password fields
  final TextEditingController emailController    = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  /// FocusNodes for controlling focus
  final FocusNode emailFocusNode     = FocusNode();
  final FocusNode passWordFocusNode  = FocusNode();

  /// Toggles whether the password is obscured
  bool _obscurePassword = true;

  /// Key for validating the form fields
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    // e.g., analytics, load saved credentials, etc.
  }

  /// Tries signing in with email/password after validating the form
  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return; // validation fail

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    await ref.read(firebaseAuthNotifierProvider.notifier).signIn(email, password);

    final authState = ref.read(firebaseAuthNotifierProvider);
    if (authState is DataSuccess<void>) {
      toast("Login successful!");
      // TODO: navigate to your main screen
    } else if (authState is DataFailed<void>) {
      final errorMsg = authState.error?.error ?? 'Unknown error';
      toast("Login failed: $errorMsg");
    }
  }

  /// Called when the user taps "Sign in with Google."
  /// We'll add the logic in your domain/data layers next,
  /// but for now just a placeholder.
  Future<void> _handleGoogleSignIn() async {
    // 1) Trigger the Notifier method
    await ref.read(firebaseAuthNotifierProvider.notifier).signInWithGoogle();

    // 2) Check the final state
    final authState = ref.read(firebaseAuthNotifierProvider);
    if (authState is DataSuccess<void>) {
      toast("Google sign-in successful!");
      // TODO: navigate to your main screen
    } else if (authState is DataFailed<void>) {
      final errorMsg = authState.error?.error ?? 'Unknown error';
      toast("Google sign-in failed: $errorMsg");
      print("Google sign-in failed: $errorMsg");
    }
  }


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(firebaseAuthNotifierProvider);
    final double screenWidth  = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
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
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
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
                            Text("Password", style: boldTextStyle(size: 14)),
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
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
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
                                    builder: (dialogCtx) => const ForgotPasswordDialog(),
                                  );
                                },
                                child: Text(
                                  "Forgot password?",
                                  style: primaryTextStyle(),
                                ),
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
                            Center(
                              child: SizedBox(
                                width: 200,
                                child: Row(
                                  children: [
                                    const Expanded(child: Divider(thickness: 2)),
                                    const SizedBox(width: 8),
                                    Text('or', style: boldTextStyle(size: 16, color: Colors.grey)),
                                    const SizedBox(width: 8),
                                    const Expanded(child: Divider(thickness: 2)),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),
                            // Social login row (just Google now)
                            Center(
                              child: InkWell(
                                onTap: _handleGoogleSignIn,
                                child: Container(
                                  decoration: boxDecorationRoundedWithShadow(
                                    16,
                                    backgroundColor: context.cardColor,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GoogleLogoWidget(size: 40),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Sign in with Google",
                                        style: boldTextStyle(),
                                      ),
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
                                    MaterialPageRoute(builder: (context) => const SignUpScreen()),
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Don't have an account?",
                                      style: primaryTextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(width: 4),
                                    Text('Register here', style: boldTextStyle(color: black)),
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
    );
  }
}
