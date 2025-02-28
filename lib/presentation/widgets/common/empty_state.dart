// lib/presentation/widgets/common/empty_state.dart

import 'package:flutter/material.dart';
import 'package:vouse_flutter/core/util/colors.dart';

/// A customizable empty state widget for displaying when no content is available.
///
/// Features:
/// - Consistent styling with customization options
/// - Icon, title, message, and action button
/// - Animation support
///
/// Usage:
/// ```dart
/// EmptyState(
///   icon: Icons.post_add,
///   title: 'No posts yet',
///   message: 'Your published posts will appear here',
///   buttonText: 'Create Post',
///   onButtonPressed: () => _navigateToCreatePost(),
/// )
/// ```
class EmptyState extends StatelessWidget {
  /// The icon to display
  final IconData icon;

  /// The title text
  final String title;

  /// The message text
  final String message;

  /// The action button text
  final String? buttonText;

  /// Callback when the action button is pressed
  final VoidCallback? onButtonPressed;

  /// Icon color
  final Color? iconColor;

  /// Title text style
  final TextStyle? titleStyle;

  /// Message text style
  final TextStyle? messageStyle;

  /// Creates an [EmptyState] widget.
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
    this.iconColor,
    this.titleStyle,
    this.messageStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: (iconColor ?? vPrimaryColor).withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: iconColor ?? vPrimaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: titleStyle ?? TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: vPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: messageStyle ?? TextStyle(
                  fontSize: 16,
                  color: vBodyGrey,
                ),
              ),
              if (buttonText != null && onButtonPressed != null) ...[
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: onButtonPressed,
                  icon: const Icon(Icons.add),
                  label: Text(buttonText!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: vPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}