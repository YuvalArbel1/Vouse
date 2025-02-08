import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart'; // For text styles, e.g., boldTextStyle
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/presentation/providers/auth/firebase_auth_notifier.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import '../../../core/util/colors.dart';
import '../../../core/util/common.dart';

/// A dialog widget that prompts the user for their email to reset the password.
/// If successful, we show a toast & close the dialog. If an error occurs,
/// we show inline red text so the user can correct or try again.
class ForgotPasswordDialog extends ConsumerStatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  ConsumerState<ForgotPasswordDialog> createState() =>
      _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<ForgotPasswordDialog> {
  /// A form key to validate the email input.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Text controller for the email field.
  final TextEditingController emailController = TextEditingController();

  /// FocusNode if needed.
  final FocusNode emailFocusNode = FocusNode();

  /// Tells us if we should show a spinner while waiting for Firebase.
  bool _isLoading = false;

  /// Inline error message from Firebase (e.g. invalid-email).
  String? _errorMessage;

  /// Called when the user taps "Send Reset"
  /// 1) Validate form
  /// 2) Call forgotPassword in the Notifier
  /// 3) If success, toast + close. If failure, inline error.
  Future<void> _handleForgotPassword() async {
    // 1) Validate the form
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // invalid input
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    // 2) Attempt to reset
    final email = emailController.text.trim();
    await ref.read(firebaseAuthNotifierProvider.notifier).forgotPassword(email);

    setState(() {
      _isLoading = false;
    });

    // 3) Check result
    final state = ref.read(firebaseAuthNotifierProvider);
    if (state is DataSuccess<void>) {
      toast("Reset email sent! Check your inbox.");
      Navigator.pop(context); // close dialog
    } else if (state is DataFailed<void>) {
      final errorMsg = state.error?.error ?? 'Unknown error';
      setState(() {
        _errorMessage = errorMsg as String?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(8),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reset Password',
                  style: boldTextStyle(size: 20, color: black)),
              const SizedBox(height: 8),

              Text(
                'Enter your email address to receive a password reset link.',
                style: primaryTextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Email field
              TextFormField(
                controller: emailController,
                focusNode: emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                decoration: waInputDecoration(
                  hint: 'Your email address',
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

              // Error inline (if any)
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: primaryTextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16),

              // If loading, show spinner. Otherwise show action buttons.
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel',
                          style: boldTextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _handleForgotPassword,
                      child: Text(
                        'Send Reset',
                        style: boldTextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
