// lib/presentation/widgets/post/post_option_icon.dart

import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../core/util/colors.dart';

/// A reusable widget function that creates a small icon with label below.
/// Typically used in PostOptions row:
///   buildOptionIcon(
///     icon: Icons.camera_alt,
///     label: 'Camera',
///     onTap: () { ... },
///   )
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
            color: getColorFromCardOrPrimary(), // see below for example usage
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: vPrimaryColor),
        ),
        const SizedBox(height: 4),
        Text(label, style: secondaryTextStyle(size: 12, color: vBodyWhite)),
      ],
    ),
  );
}

/// If you want to do something custom for color logic:
Color getColorFromCardOrPrimary() {
  // Example: return context.cardColor or Colors.white
  // For now, let's do 'white' or context.cardColor.
  // You can adapt this as you see fit in your actual app code.
  return getColorFromTheme(); // or context.cardColor, etc.
}

/// Example of a function that picks color from theme
Color getColorFromTheme() {
  // If you have a BuildContext, you might do:
  // final context = nbContext; <-- or pass context in
  // return context.cardColor;
  // Here, let's just return a neutral color for demonstration:
  return Colors.white;
}
