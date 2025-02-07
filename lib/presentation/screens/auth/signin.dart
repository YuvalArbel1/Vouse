import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:vouse_flutter/presentation/screens/auth/signup.dart';

import '../../../core/util/colors.dart';
import '../../../core/util/common.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passWordFocusNode = FocusNode();

  // This boolean controls whether the password is obscured.
  bool _obscurePassword = true;
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    // Your initialization logic (if any)
  }

  @override
  Widget build(BuildContext context) {
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
                    Container(
                      width: screenWidth,
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      margin: const EdgeInsets.only(top: 55.0),
                      decoration: boxDecorationWithShadow(
                        borderRadius: BorderRadius.circular(30),
                        backgroundColor: context.cardColor,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 50),
                          Text("Email", style: boldTextStyle(size: 14)),
                          const SizedBox(height: 8),
                          AppTextField(
                            decoration: waInputDecoration(
                              hint: 'Enter your email here',
                              prefixIcon: Icons.email_outlined,
                            ),
                            textFieldType: TextFieldType.EMAIL,
                            keyboardType: TextInputType.emailAddress,
                            controller: emailController,
                            focus: emailFocusNode,
                            nextFocus: passWordFocusNode,
                          ),
                          const SizedBox(height: 16),
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
                                  color: VPrimaryColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "Forgot password?",
                              style: primaryTextStyle(),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Padding(
                            padding: EdgeInsets.only(
                              left: screenWidth * 0.1,
                              right: screenWidth * 0.1,
                            ),
                            child: AppButton(
                              text: "Log In",
                              color: VPrimaryColor,
                              textColor: Colors.white,
                              shapeBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              width: screenWidth,
                              onTap: () {
                                // Your log in logic here
                              },
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
                                  Text(
                                    'or',
                                    style: boldTextStyle(
                                        size: 16, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(child: Divider(thickness: 2)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          // Social login row
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
                                    builder: (context) => const SignUpScreen(),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account?",
                                    style: primaryTextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Register here',
                                    style: boldTextStyle(color: black),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                        color: VPrimaryColor,
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
