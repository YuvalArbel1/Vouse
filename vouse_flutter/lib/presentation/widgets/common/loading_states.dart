// lib/presentation/widgets/common/loading_states.dart

import 'package:flutter/material.dart';
import 'package:vouse_flutter/core/util/colors.dart';

/// A widget that displays a shimmer loading effect.
///
/// Features:
/// - Customizable colors and animation speeds
/// - Various preset shapes (rectangle, circle, rounded rectangle)
/// - Can be combined to create complex loading UI patterns
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

/// A widget that displays a post card loading state.
///
/// Features:
/// - Simulates the appearance of a loading post card
/// - Customizable dimensions and appearance
/// - Animated shimmer effect
///
/// Usage:
/// ```dart
/// PostCardLoading(
///   height: 350,
///   width: 280,
/// )
/// ```
class PostCardLoading extends StatelessWidget {
  /// Width of the card
  final double width;

  /// Height of the card
  final double height;

  /// Whether to show a title shimmer
  final bool showTitle;

  /// Whether to show image shimmers
  final bool showImages;

  /// Whether to show metadata shimmers
  final bool showMetadata;

  /// Creates a [PostCardLoading] widget.
  const PostCardLoading({
    super.key,
    this.width = 280,
    this.height = 350,
    this.showTitle = true,
    this.showImages = true,
    this.showMetadata = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          if (showTitle) ...[
            ShimmerLoading.roundedRectangle(
              width: width * 0.7,
              height: 24,
            ),
            const SizedBox(height: 16),
          ],

          // Content
          ShimmerLoading.roundedRectangle(
            width: double.infinity,
            height: 100,
          ),

          const Spacer(),

          // Images
          if (showImages) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ShimmerLoading.roundedRectangle(
                    width: 60,
                    height: 60,
                    borderRadius: 8,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],

          // Metadata
          if (showMetadata) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerLoading.roundedRectangle(
                  width: 80,
                  height: 20,
                ),
                ShimmerLoading.roundedRectangle(
                  width: 100,
                  height: 20,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A widget that displays a horizontal list of loading post cards.
///
/// Features:
/// - Simulates the appearance of a loading posts list
/// - Customizable number of cards and dimensions
///
/// Usage:
/// ```dart
/// HorizontalPostListLoading(
///   itemCount: 3,
///   cardHeight: 350,
///   cardWidth: 280,
/// )
/// ```
class HorizontalPostListLoading extends StatelessWidget {
  /// Number of loading cards to display
  final int itemCount;

  /// Height of each card
  final double cardHeight;

  /// Width of each card
  final double cardWidth;

  /// Whether to show title shimmers
  final bool showTitle;

  /// Whether to show image shimmers
  final bool showImages;

  /// Whether to show metadata shimmers
  final bool showMetadata;

  /// Creates a [HorizontalPostListLoading] widget.
  const HorizontalPostListLoading({
    super.key,
    this.itemCount = 3,
    this.cardHeight = 350,
    this.cardWidth = 280,
    this.showTitle = true,
    this.showImages = true,
    this.showMetadata = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: PostCardLoading(
              width: cardWidth,
              height: cardHeight,
              showTitle: showTitle,
              showImages: showImages,
              showMetadata: showMetadata,
            ),
          );
        },
      ),
    );
  }
}

/// A widget that displays a post timeline loading state.
///
/// Features:
/// - Simulates the appearance of a loading timeline
/// - Customizable number of items and dimensions
/// - Matching visual style with real timeline items
/// - Shimmer animation effects for better user experience
///
/// Usage:
/// ```dart
/// PostTimelineLoading(
///   itemCount: 3,
/// )
/// ```
class PostTimelineLoading extends StatelessWidget {
  /// Number of loading timeline items to display
  final int itemCount;

  /// Height of each card
  final double cardHeight;

  /// Creates a [PostTimelineLoading] widget.
  const PostTimelineLoading({
    super.key,
    this.itemCount = 3,
    this.cardHeight = 300,
  });

  @override
  Widget build(BuildContext context) {
    // Use ListView to prevent overflow
    return ListView.builder(
      shrinkWrap: true, // Ensures the ListView takes only needed space
      physics: const NeverScrollableScrollPhysics(), // Prevents scrolling within this component
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline visualization
              Column(
                children: [
                  // Time indicator dot
                  ShimmerLoading.circle(size: 24),

                  // Connecting line (hide for last item)
                  if (index < itemCount - 1)
                    Container(
                      width: 2,
                      height: cardHeight,
                      color: vAccentColor.withAlpha(100), // Use accent color to match real timeline
                    ),
                ],
              ),

              const SizedBox(width: 16),

              // Post content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date/time header shimmer
                    ShimmerLoading.roundedRectangle(
                      width: 150,
                      height: 30,
                      borderRadius: 20,
                    ),

                    const SizedBox(height: 8),

                    // Post card shimmer
                    SizedBox(
                      height: cardHeight,
                      child: PostCardLoading(
                        width: double.infinity,
                        height: cardHeight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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