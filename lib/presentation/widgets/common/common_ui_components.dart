// lib/presentation/widgets/common/common_ui_components.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/domain/entities/local_db/user_entity.dart';

/// A reusable profile avatar widget.
///
/// Features:
/// - Displays user avatar with fallback icon
/// - Optional edit capability
/// - Consistent styling
class ProfileAvatarDisplay extends StatelessWidget {
  /// The user entity containing profile data
  final UserEntity? user;

  /// Size of the avatar
  final double size;

  /// Whether to show edit border styling
  final bool showEditStyle;

  /// Callback when tapped
  final VoidCallback? onTap;

  /// Whether to use hero animation
  final bool useHero;

  /// Hero tag to use
  final String heroTag;

  /// Creates a profile avatar display widget
  const ProfileAvatarDisplay({
    super.key,
    required this.user,
    this.size = 60,
    this.showEditStyle = false,
    this.onTap,
    this.useHero = false,
    this.heroTag = 'profile-avatar',
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarContainer = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: vPrimaryColor.withAlpha(26),
          border: Border.all(
            color: showEditStyle ? vPrimaryColor : Colors.transparent,
            width: showEditStyle ? 2 : 0,
          ),
          boxShadow: showEditStyle
              ? [
                  BoxShadow(
                    color: vPrimaryColor.withAlpha(40),
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
          image: user?.avatarPath != null
              ? DecorationImage(
                  image: FileImage(File(user!.avatarPath!)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: user?.avatarPath == null
            ? Icon(
                Icons.person,
                color: vPrimaryColor,
                size: size * 0.5,
              )
            : null,
      ),
    );

    if (useHero) {
      return Hero(
        tag: heroTag,
        child: avatarContainer,
      );
    }

    return avatarContainer;
  }
}

/// A reusable card container with consistent styling.
///
/// Features:
/// - Consistent card styling across app
/// - Customizable styling
/// - Shadow and border radius
class VouseCard extends StatelessWidget {
  /// The content of the card
  final Widget child;

  /// Padding inside the card
  final EdgeInsetsGeometry padding;

  /// Margin around the card
  final EdgeInsetsGeometry margin;

  /// Border radius of the card
  final double borderRadius;

  /// Whether to use elevation
  final bool elevated;

  /// Background color of the card
  final Color? backgroundColor;

  /// Creates a VouseCard
  const VouseCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(0),
    this.borderRadius = 16,
    this.elevated = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// A rounded button with consistent styling.
///
/// Features:
/// - Extends ElevatedButton with app-specific styling
/// - Various style options (primary, accent, outline)
/// - Consistent styling across app
class VouseButton extends StatelessWidget {
  /// Button text
  final String text;

  /// Callback when pressed
  final VoidCallback? onPressed;

  /// Icon to display
  final IconData? icon;

  /// Button style variant
  final VouseButtonStyle style;

  /// Width of the button
  final double? width;

  /// Whether to use loading state
  final bool isLoading;

  /// Creates a VouseButton
  const VouseButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.style = VouseButtonStyle.primary,
    this.width,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle(context);

    Widget buttonChild = Text(text);

    if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    if (isLoading) {
      buttonChild = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          color:
              style == VouseButtonStyle.outline ? vPrimaryColor : Colors.white,
          strokeWidth: 2,
        ),
      );
    }

    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: buttonChild,
      ),
    );
  }

  /// Helper to get button style based on variant
  ButtonStyle _getButtonStyle(BuildContext context) {
    switch (style) {
      case VouseButtonStyle.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: vPrimaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      case VouseButtonStyle.accent:
        return ElevatedButton.styleFrom(
          backgroundColor: vAccentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      case VouseButtonStyle.outline:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: vPrimaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: vPrimaryColor),
          ),
        );
    }
  }
}

/// Button style variants
enum VouseButtonStyle {
  /// Primary purple style
  primary,

  /// Green accent style
  accent,

  /// Outlined style
  outline,
}

/// A gradient header container with consistent styling.
///
/// Features:
/// - Gradient background
/// - Rounded bottom corners
/// - Optional shadow
class GradientHeaderContainer extends StatelessWidget {
  /// The content of the header
  final Widget child;

  /// Start color of gradient
  final Color startColor;

  /// End color of gradient
  final Color endColor;

  /// Height of the header
  final double? height;

  /// Padding inside the header
  final EdgeInsetsGeometry padding;

  /// Creates a gradient header container
  const GradientHeaderContainer({
    super.key,
    required this.child,
    required this.startColor,
    required this.endColor,
    this.height,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: child,
    );
  }
}

/// A reusable stat chip for displaying metrics.
///
/// Features:
/// - Consistent styling for stat chips
/// - Label and value display
/// - Optional icon
class StatChip extends StatelessWidget {
  /// The label text
  final String label;

  /// The value text
  final String value;

  /// Optional icon
  final IconData? icon;

  /// Background color
  final Color backgroundColor;

  /// Text color
  final Color textColor;

  /// Creates a stat chip
  const StatChip({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor.withAlpha(51),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: textColor, size: 16),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor.withAlpha(204),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
