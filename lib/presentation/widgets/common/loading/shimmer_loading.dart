// lib/presentation/widgets/common/loading/shimmer_loading.dart

import 'package:flutter/material.dart';

/// A widget that displays a shimmer loading effect.
///
/// Features:
/// - Customizable colors and animation speeds
/// - Various preset shapes (rectangle, circle, rounded rectangle)
/// - Can be combined to create complex loading UI patterns
///
/// Usage:
/// ```dart
/// ShimmerLoading(
///   width: double.infinity,
///   height: 24,
///   borderRadius: 8,
/// )
/// ```
class ShimmerLoading extends StatefulWidget {
  /// Width of the shimmer container
  final double width;

  /// Height of the shimmer container
  final double height;

  /// Border radius of the container (0 for rectangle, infinity for circle)
  final double borderRadius;

  /// Base color of the shimmer effect
  final Color baseColor;

  /// Highlight color of the shimmer effect
  final Color highlightColor;

  /// Duration of one shimmer animation cycle
  final Duration duration;

  /// Creates a [ShimmerLoading] widget.
  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 0,
    this.baseColor = const Color(0xFFEEEEEE),
    this.highlightColor = Colors.white,
    this.duration = const Duration(milliseconds: 1500),
  });

  /// Creates a circular shimmer loading effect.
  ///
  /// The [size] parameter is used for both width and height.
  factory ShimmerLoading.circle({
    Key? key,
    required double size,
    Color baseColor = const Color(0xFFEEEEEE),
    Color highlightColor = Colors.white,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return ShimmerLoading(
      key: key,
      width: size,
      height: size,
      borderRadius: size / 2,
      baseColor: baseColor,
      highlightColor: highlightColor,
      duration: duration,
    );
  }

  /// Creates a rounded rectangle shimmer loading effect.
  factory ShimmerLoading.roundedRectangle({
    Key? key,
    required double width,
    required double height,
    double borderRadius = 8,
    Color baseColor = const Color(0xFFEEEEEE),
    Color highlightColor = Colors.white,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return ShimmerLoading(
      key: key,
      width: width,
      height: height,
      borderRadius: borderRadius,
      baseColor: baseColor,
      highlightColor: highlightColor,
      duration: duration,
    );
  }

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.baseColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                _animation.value - 1,
                _animation.value,
                _animation.value + 1,
              ],
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
            ),
          ),
        );
      },
    );
  }
}