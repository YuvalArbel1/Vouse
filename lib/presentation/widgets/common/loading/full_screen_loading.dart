// lib/presentation/widgets/common/loading/full_screen_loading.dart

import 'package:flutter/material.dart';
import 'package:vouse_flutter/core/util/colors.dart';

/// A widget that displays a full screen loading state.
///
/// Features:
/// - Center-aligned loading indicator
/// - Optional loading message
/// - Customizable colors and appearance
///
/// Usage:
/// ```dart
/// FullScreenLoading(
///   message: 'Loading your posts...',
/// )
/// ```
class FullScreenLoading extends StatelessWidget {
  /// Optional loading message
  final String? message;

  /// Color of the loading indicator
  final Color color;

  /// Background color of the loading screen
  final Color? backgroundColor;

  /// Creates a [FullScreenLoading] widget.
  const FullScreenLoading({
    super.key,
    this.message,
    this.color = vPrimaryColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: color,
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: TextStyle(
                  color: vBodyGrey,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A widget that blocks UI interaction and displays a loading spinner.
///
/// Features:
/// - Full screen overlay with semi-transparent background
/// - Centered loading indicator
/// - Can be conditionally shown/hidden
class BlockingSpinnerOverlay extends StatelessWidget {
  /// Whether the overlay is visible
  final bool isVisible;

  /// Optional loading message
  final String? message;

  /// Creates a [BlockingSpinnerOverlay].
  const BlockingSpinnerOverlay({
    super.key,
    required this.isVisible,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}