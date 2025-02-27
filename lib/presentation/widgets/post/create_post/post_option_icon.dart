// lib/presentation/widgets/post/post_option_icon.dart

import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../core/util/colors.dart';

/// A reusable widget function that creates a small icon with label below.
Widget buildOptionIcon({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: getColorFromCardOrPrimary(),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: vPrimaryColor),
        ),
        const SizedBox(height: 4),
        Text(label, style: secondaryTextStyle(size: 12, color: vBodyGrey)),
      ],
    ),
  );
}

Color getColorFromCardOrPrimary() {
  return getColorFromTheme();
}

Color getColorFromTheme() {
  return Colors.white;
}
