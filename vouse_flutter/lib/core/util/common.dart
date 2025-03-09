// lib/core/util/common.dart

import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'colors.dart';

/// Blocks UI interaction and displays a loading spinner.
class BlockingSpinnerOverlay extends StatelessWidget {
  final bool isVisible;

  const BlockingSpinnerOverlay({
    super.key,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();
    return Container(
      color: Colors.black54,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Provides consistent input styling.
InputDecoration vInputDecoration({
  IconData? prefixIcon,
  String? hint,
  Color? bgColor,
  Color? borderColor,
  EdgeInsets? padding,
}) {
  final radius = BorderRadius.circular(16);

  // Alpha values for replacements of .withOpacity
  const fillAlpha = 10;  // ~4%
  const greyAlpha = 51;  // ~20%

  return InputDecoration(
    contentPadding: padding ?? const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    counter: const Offstage(),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: borderColor ?? vPrimaryColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: Colors.grey.withAlpha(greyAlpha)),
    ),
    fillColor: bgColor ?? vPrimaryColor.withAlpha(fillAlpha),
    hintText: hint,
    prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: vPrimaryColor) : null,
    hintStyle: secondaryTextStyle(),
    filled: true,
    errorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: Colors.red, width: 1.2),
    ),
    errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
  );
}

/// A reusable container decoration for cards or panels.
BoxDecoration vouseBoxDecoration({
  double radius = 12,
  Color? backgroundColor,
  int shadowOpacity = 20,
  double blurRadius = 6,
  Offset offset = const Offset(0, 4),
}) {
  return BoxDecoration(
    color: backgroundColor ?? vAppLayoutBackground,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha(shadowOpacity),
        blurRadius: blurRadius,
        offset: offset,
      ),
    ],
  );
}
