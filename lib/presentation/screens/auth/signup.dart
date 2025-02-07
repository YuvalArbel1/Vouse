import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../core/util/colors.dart';
import '../../../core/util/common.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final FocusNode fullNameFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passWordFocusNode = FocusNode();
  final FocusNode confirmPassWordFocusNode = FocusNode();

  // Use separate booleans to control password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
              Text(
                "Register New Account",
                style: boldTextStyle(size: 24, color: black),
              ),
              Container(
                margin: const EdgeInsets.all(16),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: <Widget>[
                    Container(
                      width: screenWidth,
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 16),
                      margin: const EdgeInsets.only(top: 55.0),
                      decoration: boxDecorationWithShadow(
                        borderRadius: BorderRadius.circular(30),
                        backgroundColor: context.cardColor,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 50),
                              Text("Full Name", style: boldTextStyle(size: 14)),
                              const SizedBox(height: 8),
                              // Using AppTextField for non-password fields
                              AppTextField(
                                controller: fullNameController,
                                focus: fullNameFocusNode,
                                nextFocus: emailFocusNode,
                                textFieldType: TextFieldType.NAME,
                                keyboardType: TextInputType.name,
                                decoration: waInputDecoration(
                                  hint: 'Enter your full name here',
                                  prefixIcon: Icons.person_outline_outlined,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text("Email", style: boldTextStyle(size: 14)),
                              const SizedBox(height: 8),
                              AppTextField(
                                controller: emailController,
                                focus: emailFocusNode,
                                nextFocus: passWordFocusNode,
                                textFieldType: TextFieldType.EMAIL,
                                keyboardType: TextInputType.emailAddress,
                                decoration: waInputDecoration(
                                  hint: 'Enter your email here',
                                  prefixIcon: Icons.email_outlined,
                                ),
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
                              Text("Confirm Password",
                                  style: boldTextStyle(size: 14)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: confirmPasswordController,
                                focusNode: confirmPassWordFocusNode,
                                obscureText: _obscureConfirmPassword,
                                keyboardType: TextInputType.text,
                                decoration: waInputDecoration(
                                  hint: 'Re-type password',
                                  prefixIcon: Icons.lock_outline,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: VPrimaryColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              Padding(
                                padding: EdgeInsets.only(
                                  left: screenWidth * 0.1,
                                  right: screenWidth * 0.1,
                                ),
                                child: AppButton(
                                  text: "Register Account",
                                  color: VPrimaryColor,
                                  textColor: Colors.white,
                                  shapeBorder: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  width: screenWidth,
                                  onTap: () {
                                    // Your register account logic here
                                  },
                                ),
                              ),
                              const SizedBox(height: 30),
                              Center(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Already have an account?',
                                        style: primaryTextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Log In here',
                                        style: boldTextStyle(color: black),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
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
                        fit: BoxFit.cover,
                        color: VPrimaryColor,
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
