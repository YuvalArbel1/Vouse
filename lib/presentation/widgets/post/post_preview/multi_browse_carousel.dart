// lib/presentation/widgets/post/post_preview/dynamic_multi_browse_carousel.dart

import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:vouse_flutter/presentation/widgets/post/post_preview/post_card.dart';

import '../../../../core/util/colors.dart';
import '../../../../domain/entities/local_db/post_entity.dart';
import '../../../providers/home/home_posts_providers.dart';

/// A dynamic multi-browse carousel with intelligent navigation indicators.
///
/// Provides smooth scrolling and context-aware navigation hints for different
/// post types (Posted, Scheduled, Drafts).
class DynamicMultiBrowseCarousel extends ConsumerStatefulWidget {
  /// Creates a [DynamicMultiBrowseCarousel] widget.
  const DynamicMultiBrowseCarousel({super.key});

  @override
  _DynamicMultiBrowseCarouselState createState() =>
      _DynamicMultiBrowseCarouselState();
}

class _DynamicMultiBrowseCarouselState
    extends ConsumerState<DynamicMultiBrowseCarousel> {
  /// Controllers for each post type section
  late PageController _postedController;
  late PageController _scheduledController;
  late PageController _draftsController;

  @override
  void initState() {
    super.initState();
    // Initialize PageControllers with specific properties
    _postedController = PageController(
      viewportFraction: 0.8,
      initialPage: 0,
    );
    _scheduledController = PageController(
      viewportFraction: 0.8,
      initialPage: 0,
    );
    _draftsController = PageController(
      viewportFraction: 0.8,
      initialPage: 0,
    );
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _postedController.dispose();
    _scheduledController.dispose();
    _draftsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Posted Posts Section
        _buildSectionHeader('Posted', Icons.check_circle),
        _buildCarouselSection(
          ref.watch(postedPostsProvider),
          _postedController,
        ),

        const SizedBox(height: 16),

        // Scheduled Posts Section
        _buildSectionHeader('Scheduled', Icons.schedule),
        _buildCarouselSection(
          ref.watch(scheduledPostsProvider),
          _scheduledController,
        ),

        const SizedBox(height: 16),

        // Drafts Section
        _buildSectionHeader('Drafts', Icons.edit_note),
        _buildCarouselSection(
          ref.watch(draftPostsProvider),
          _draftsController,
        ),
      ],
    );
  }

  /// Builds a section header with icon and title
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: vPrimaryColor),
          const SizedBox(width: 8),
          Text(title, style: boldTextStyle(size: 18)),
        ],
      ),
    );
  }

  /// Builds a carousel section with intelligent navigation
  Widget _buildCarouselSection(
    AsyncValue<List<PostEntity>> asyncPosts,
    PageController controller,
  ) {
    return asyncPosts.when(
      data: (posts) {
        if (posts.isEmpty) {
          return _buildEmptyState();
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 420,
              child: PageView.builder(
                controller: controller,
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: controller,
                    builder: (context, child) {
                      double value = 1.0;
                      if (controller.position.haveDimensions) {
                        value = controller.page! - index;
                        value = (1 - (value.abs() * 0.3)).clamp(0.5, 1.0);
                      }

                      return Center(
                        child: SizedBox(
                          height: Curves.easeInOut.transform(value) * 420,
                          width: Curves.easeInOut.transform(value) * 320,
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: PostCard(post: posts[index]),
                    ),
                  );
                },
              ),
            ),

            // Navigation Indicators
            if (posts.length > 1) ...[
              // Left Navigation Indicator
              Positioned(
                left: 0,
                child: _buildNavigationIndicator(
                  direction: -1,
                  controller: controller,
                  postCount: posts.length,
                ),
              ),

              // Right Navigation Indicator
              Positioned(
                right: 0,
                child: _buildNavigationIndicator(
                  direction: 1,
                  controller: controller,
                  postCount: posts.length,
                ),
              ),
            ]
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('Error: $error'),
    );
  }

  /// Builds a context-aware navigation indicator
  Widget _buildNavigationIndicator({
    required int direction,
    required PageController controller,
    required int postCount,
  }) {
    // Calculate the current page based on the controller's current state
    int currentPage = controller.hasClients ? controller.page?.round() ?? 0 : 0;

    // Determine if navigation is possible
    bool canNavigate =
        direction > 0 ? currentPage < postCount - 1 : currentPage > 0;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: canNavigate ? 1.0 : 0.0,
      child: GestureDetector(
        onTap: canNavigate
            ? () {
                controller.animateToPage(
                  currentPage + direction,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            : null,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                vPrimaryColor.withAlpha((canNavigate ? 51 : 0)),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          // Ensure perfect centering
          child: Icon(
            direction > 0 ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
            color:
                canNavigate ? vPrimaryColor.withAlpha(178) : Colors.transparent,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Displays an empty state when no posts are available
  Widget _buildEmptyState() {
    return Container(
      height: 180,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(200),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: vPrimaryColor.withAlpha(50)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 40, color: vPrimaryColor.withAlpha(150)),
          const SizedBox(height: 8),
          Text(
            'No posts yet',
            style: secondaryTextStyle(color: vBodyGrey),
          ),
        ],
      ),
    );
  }
}
