// lib/presentation/widgets/forgot_password_dialog.dart

import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart'; // For text styles, e.g., boldTextStyle
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/presentation/providers/auth/firebase/firebase_auth_notifier.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import '../../../core/util/colors.dart';
import '../../../core/util/common.dart';

/// A dialog widget that prompts the user for their email to reset the password.
/// If successful, a toast is shown and the dialog is closed. If an error occurs,
/// an inline error message is displayed so the user can correct or try again.
class ForgotPasswordDialog extends ConsumerStatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  ConsumerState<ForgotPasswordDialog> createState() =>
      _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<ForgotPasswordDialog> {
  /// Form key to validate the email input.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Controller for the email text field.
  final TextEditingController emailController = TextEditingController();

  /// FocusNode for the email text field.
  final FocusNode emailFocusNode = FocusNode();

  /// Indicates if a spinner should be shown while waiting for Firebase.
  bool _isLoading = false;

  /// Inline error message returned from Firebase (e.g. invalid-email).
  String? _errorMessage;

  /// Handles the "Send Reset" action.
  ///
  /// 1. Validates the form.
  /// 2. Calls forgotPassword in the Notifier.
  /// 3. On success, shows a toast and closes the dialog.
  ///    On failure, displays an inline error message.
  Future<void> _handleForgotPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // Invalid input
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final email = emailController.text.trim();
    await ref.read(firebaseAuthNotifierProvider.notifier).forgotPassword(email);

    // Check if the widget is still mounted before proceeding.
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    final state = ref.read(firebaseAuthNotifierProvider);
    if (state is DataSuccess<void>) {
      toast("Reset email sent! Check your inbox.");
      if (mounted) Navigator.pop(context);
    } else if (state is DataFailed<void>) {
      final errorMsg = state.error?.error ?? 'Unknown error';
      setState(() {
        _errorMessage = errorMsg as String?;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    emailFocusNode.dispose();
    super.dispose();
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
              Text(
                'Reset Password',
                style: boldTextStyle(size: 20, color: black),
              ),
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
              // Inline error message (if any)
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: primaryTextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16),
              // Loading spinner or action buttons
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: boldTextStyle(color: Colors.grey),
                      ),
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
