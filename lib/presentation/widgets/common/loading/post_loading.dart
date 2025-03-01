// lib/presentation/widgets/common/loading/post_loading.dart

import 'package:flutter/material.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'shimmer_loading.dart';

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(itemCount, (index) {
          return Row(
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
                      height: cardHeight + 20,
                      color: Colors.grey.withAlpha(100),
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

                    if (index < itemCount - 1)
                      const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// A widget that displays a home screen loading state
///
/// Features:
/// - Simulates the appearance of the home screen while loading
/// - Includes header, action buttons, and content sections
class HomeScreenLoading extends StatelessWidget {
  /// Creates a [HomeScreenLoading] widget
  const HomeScreenLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: vAppLayoutBackground,
      child: Column(
        children: [
          // Shimmer for header
          Container(
            height: 140,
            width: double.infinity,
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShimmerLoading.circle(size: 60),
                const SizedBox(height: 12),
                ShimmerLoading.roundedRectangle(
                  width: 150,
                  height: 20,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Shimmer for action buttons
          ShimmerLoading.roundedRectangle(
            width: double.infinity,
            height: 120,
            borderRadius: 20,
          ),

          const SizedBox(height: 20),

          // Shimmer for content sections
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading.roundedRectangle(
                  width: 200,
                  height: 24,
                  borderRadius: 4,
                ),
                const SizedBox(height: 16),
                const HorizontalPostListLoading(),

                const SizedBox(height: 24),

                ShimmerLoading.roundedRectangle(
                  width: 200,
                  height: 24,
                  borderRadius: 4,
                ),
                const SizedBox(height: 16),
                const HorizontalPostListLoading(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}