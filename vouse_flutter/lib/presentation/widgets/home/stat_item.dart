// lib/presentation/widgets/home/stat_item.dart

import 'package:flutter/material.dart';
import 'package:vouse_flutter/core/util/colors.dart';

/// A widget for displaying a statistic in the user profile section.
///
/// Features:
/// - Icon with count and label
/// - Customizable colors and styling
class StatItem extends StatelessWidget {
  /// The label for this statistic
  final String label;

  /// The count value
  final int count;

  /// The icon to display
  final IconData icon;

  /// The color for the icon and count
  final Color color;

  /// Creates a [StatItem] widget.
  const StatItem({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: vBodyGrey,
          ),
        ),
      ],
    );
  }
}