import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/presentation/providers/firebase_auth_notifier.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import '../../../core/util/colors.dart';
import '../../../core/util/common.dart';
import 'signup.dart';

/// A screen that handles Firebase sign-in with form validation.
/// Uses Riverpod's firebaseAuthNotifierProvider for authentication.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  /// Text controllers for email and password input fields.
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  /// Focus nodes for each input field (if you want to manage focus).
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passWordFocusNode = FocusNode();

  /// This boolean controls whether the password text is hidden (obscured).
  bool _obscurePassword = true;

  /// A key to identify and manage our Form (for validation).
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    init();
  }

  /// Optional initialization logic.
  Future<void> init() async {
    // e.g., analytics, load saved credentials, etc.
  }

  /// Handles sign-in logic by validating the form and calling the notifier.
  Future<void> _handleLogin() async {
    // 1) Validate all fields in the Form.
    if (!(_formKey.currentState?.validate() ?? false)) {
      // If validation fails, do not proceed.
      return;
    }

    // 2) If valid, read the text fields.
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // 3) Use the Riverpod Notifier to sign in.
    await ref
        .read(firebaseAuthNotifierProvider.notifier)
        .signIn(email, password);

    // 4) Check the final auth state from the provider:
    final authState = ref.read(firebaseAuthNotifierProvider);
    if (authState is DataSuccess<void>) {
      toast("Login successful!");
    } else if (authState is DataFailed<void>) {
      // The "error" property in authState.error now has our user-friendly message
      final errorMsg = authState.error?.error ?? 'Unknown error';
      toast("Login failed: $errorMsg");
      print("Login failed: $errorMsg");
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
              Text("Log In", style: boldTextStyle(size: 24, color: black)),
              Container(
                margin: const EdgeInsets.all(16),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: <Widget>[
                    /// The main card containing the form
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
                        key: _formKey, // Associate the form with our GlobalKey
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
                                  // nb_utils has a validateEmail() extension
                                  return 'Please enter a valid email address';
                                }
                                return null; // all good
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
                                return null; // all good
                              },
                            ),

                            const SizedBox(height: 16),

                            // Forgot password link
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text("Forgot password?",
                                  style: primaryTextStyle()),
                            ),

                            const SizedBox(height: 30),

                            // Log in button (calls our named function)
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
                                onTap:
                                    _handleLogin, // use the named function here
                              ),
                            ),

                            const SizedBox(height: 30),
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

                            // Social logins row (placeholders)
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    decoration: boxDecorationRoundedWithShadow(
                                      16,
                                      backgroundColor: context.cardColor,
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Image.asset(
                                      'assets/images/wa_facebook.png',
                                      width: 40,
                                      height: 40,
                                    ),
                                  ),
                                  const SizedBox(width: 30),
                                  Container(
                                    decoration: boxDecorationRoundedWithShadow(
                                      16,
                                      backgroundColor: context.cardColor,
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: GoogleLogoWidget(size: 40),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Registration link
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
                                      style:
                                          primaryTextStyle(color: Colors.grey),
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
    );
  }
}
