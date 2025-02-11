import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import 'colors.dart';

InputDecoration waInputDecoration({
  IconData? prefixIcon,
  String? hint,
  Color? bgColor,
  Color? borderColor,
  EdgeInsets? padding,
}) {
  final radius = BorderRadius.circular(16);

  return InputDecoration(
    contentPadding: padding ?? const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    counter: const Offstage(),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: borderColor ?? vPrimaryColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
    ),
    fillColor: bgColor ?? vPrimaryColor.withOpacity(0.04),
    hintText: hint,
    prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: vPrimaryColor) : null,
    hintStyle: secondaryTextStyle(),
    filled: true,

    // Add these for consistent corners & color in error states:
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
