import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/presentation/providers/firebase_auth_notifier.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import '../../../core/util/colors.dart';
import '../../../core/util/common.dart';

/// A screen to register (sign up) a new user with Firebase.
/// Uses a Form for validation, plus the firebaseAuthNotifierProvider for sign-up logic.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  /// Controllers for text fields.
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  /// Focus nodes if you need focus control.
  final FocusNode fullNameFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passWordFocusNode = FocusNode();
  final FocusNode confirmPassWordFocusNode = FocusNode();

  /// Toggles for showing/hiding password text.
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  /// Key to manage form validation.
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    init();
  }

  /// Optional additional initialization.
  Future<void> init() async {
    // e.g., pre-fill user data, analytics, etc.
  }

  /// Handles registration after validating the form fields.
  Future<void> _handleRegister() async {
    // 1) Validate all fields inside the Form.
    if (!(_formKey.currentState?.validate() ?? false)) {
      // If not valid, do nothing.
      return;
    }

    // 2) If valid, read the text fields.
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // 3) Call the notifier to sign up.
    await ref
        .read(firebaseAuthNotifierProvider.notifier)
        .signUp(email, password);

    // 4) Check final state from auth.
    final authState = ref.read(firebaseAuthNotifierProvider);
    if (authState is DataSuccess<void>) {
      toast("Registration successful!");
      // Possibly navigate away
    } else if (authState is DataFailed<void>) {
      final errorMsg = authState.error?.error ?? 'Unknown error';
      toast("Registration failed: $errorMsg");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(firebaseAuthNotifierProvider);
    final double screenWidth = MediaQuery.of(context).size.width;
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
              Text("Register New Account",
                  style: boldTextStyle(size: 24, color: black)),
              Container(
                margin: const EdgeInsets.all(16),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: <Widget>[
                    /// Main card
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
                        key: _formKey, // Link this Form to the _formKey
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const SizedBox(height: 50),

                            // Full Name
                            Text("Full Name", style: boldTextStyle(size: 14)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: fullNameController,
                              focusNode: fullNameFocusNode,
                              keyboardType: TextInputType.name,
                              decoration: waInputDecoration(
                                hint: 'Enter your full name here',
                                prefixIcon: Icons.person_outline_outlined,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Full name is required';
                                }
                                return null; // ok
                              },
                            ),

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
                            Text("Password", style: boldTextStyle(size: 14)),
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
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters long';
                                }
                                if (!RegExp(r'[!@#\$%\^&*(),.?":{}|<>]').hasMatch(value)) {
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
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
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
                                onTap: _handleRegister, // Named function
                              ),
                            ),

                            const SizedBox(height: 30),

                            // "Already have an account?" link
                            Center(
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
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

                    // App logo at the top
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
                        fit: BoxFit.cover,
                        color: vPrimaryColor,
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
