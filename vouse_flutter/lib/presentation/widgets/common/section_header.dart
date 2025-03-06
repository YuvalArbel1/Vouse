// lib/presentation/widgets/common/section_header.dart

import 'package:flutter/material.dart';
import 'package:vouse_flutter/core/util/colors.dart';

/// A reusable section header with title and optional action button.
///
/// Features:
/// - Consistent styling across screens
/// - Optional "See all" action button
/// - Customizable colors and text styles
/// - Support for leading icon
///
/// Usage:
/// ```dart
/// SectionHeader(
///   title: 'Recent Activity',
///   onActionTap: () => _navigateToAllPosts(),
/// )
/// ```
class SectionHeader extends StatelessWidget {
  /// The section title text
  final String title;

  /// Optional callback when the action button is tapped
  final VoidCallback? onActionTap;

  /// Optional text for the action button (defaults to "See All")
  final String actionText;

  /// Optional leading icon to display before the title
  final IconData? leadingIcon;

  /// The title text style
  final TextStyle? titleStyle;

  /// The action text style
  final TextStyle? actionStyle;

  /// Creates a [SectionHeader] widget.
  const SectionHeader({
    super.key,
    required this.title,
    this.onActionTap,
    this.actionText = 'See All',
    this.leadingIcon,
    this.titleStyle,
    this.actionStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, color: vPrimaryColor, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: titleStyle ?? const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: vPrimaryColor,
            ),
          ),
          const Spacer(),
          if (onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              child: Text(
                actionText,
                style: actionStyle ?? TextStyle(
                  color: vAccentColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}