// lib/presentation/widgets/home/action_button.dart

import 'package:flutter/material.dart';
import 'package:vouse_flutter/core/util/colors.dart';

/// A quick action button for the home screen.
///
/// Features:
/// - Icon with label
/// - Circular background
/// - Customizable colors
class ActionButton extends StatelessWidget {
  /// The label for this action
  final String label;

  /// The icon to display
  final IconData icon;

  /// The color for the icon and background
  final Color color;

  /// Callback when the action is tapped
  final VoidCallback onTap;

  /// Creates an [ActionButton] widget.
  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: vBodyGrey,
            ),
          ),
        ],
      ),
    );
  }
}