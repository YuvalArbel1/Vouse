// lib/presentation/widgets/post/create_post/post_option_icon.dart

import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../core/util/colors.dart';

/// A reusable widget function that creates a small icon with label below.
///
/// Features:
/// - Visual indication of tap/hover
/// - Tooltip support
/// - Disabled state styling
/// - Customizable icon colors
/// - Consistent styling with app theme
///
/// Usage:
/// ```dart
/// buildOptionIcon(
///   icon: Icons.photo_library,
///   label: "Gallery",
///   onTap: _pickFromGallery,
///   tooltipText: "Add from gallery",
/// ),
/// ```
Widget buildOptionIcon({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  String? tooltipText,
  Color? iconColor,
  bool isDisabled = false,
}) {
  final effectiveColor = isDisabled
      ? Colors.grey.shade400
      : (iconColor ?? vPrimaryColor);

  // Create the core option widget
  final optionWidget = GestureDetector(
    onTap: isDisabled ? null : onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon container with visual feedback
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDisabled
                ? Colors.grey.withAlpha(30)
                : effectiveColor.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: effectiveColor.withAlpha(isDisabled ? 30 : 50),
              width: 1.0,
            ),
          ),
          child: Icon(
            icon,
            color: effectiveColor,
            size: 22,
          ),
        ),
        const SizedBox(height: 4),

        // Label text
        Text(
          label,
          style: secondaryTextStyle(
            size: 12,
            color: isDisabled ? Colors.grey : vBodyGrey,
          ),
        ),
      ],
    ),
  );

  // If no tooltip is provided, return the basic widget
  if (tooltipText == null || isDisabled) {
    return optionWidget;
  }

  // Otherwise wrap with tooltip
  return Tooltip(
    message: tooltipText,
    preferBelow: true,
    verticalOffset: 20,
    decoration: BoxDecoration(
      color: Colors.black.withAlpha(220),
      borderRadius: BorderRadius.circular(8),
    ),
    textStyle: const TextStyle(
      color: Colors.white,
      fontSize: 12,
    ),
    child: optionWidget,
  );
}