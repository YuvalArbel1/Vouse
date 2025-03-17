// lib/presentation/widgets/post/post_card.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/presentation/providers/post/post_refresh_provider.dart';
import 'package:vouse_flutter/presentation/providers/local_db/local_post_providers.dart';
import 'package:vouse_flutter/presentation/providers/navigation/navigation_service.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/usecases/post/delete_post_usecase.dart';

import '../../../../core/util/time_util.dart';
import '../../../../domain/entities/server/post_engagement.dart';
import '../../../../domain/usecases/server/delete_server_post_usecase.dart';
import '../../../../domain/usecases/server/get_server_post_by_local_id_usecase.dart';
import '../../../../domain/usecases/server/refresh_post_engagement_usecase.dart';
import '../../../providers/engagement/post_engagement_provider.dart';
import '../../../providers/server/server_providers.dart';

/// A post card that:
/// - If scheduled, shows a green button with the scheduled time.
/// - If posted, shows normal posted time + action icons.
///
/// Also displays a special UI for posts without images, showing a green-outlined
/// icon with custom text centered between the content and bottom bar.
class PostCard extends ConsumerWidget {
  final PostEntity post;

  /// Standard dimensions for consistent card layout
  static const double cardWidth = 320;
  static const double cardHeight = 390;

  /// Creates a [PostCard] for displaying a [post].
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isScheduled = post.scheduledAt != null && post.postIdX == null;
    final navigationService = ref.watch(navigationServiceProvider);

    // Add this line to access engagement data
    final engagementData = ref.watch(postEngagementDataProvider);
    final engagement = post.postIdX != null
        ? engagementData.engagementByPostId[post.postIdX!]
        : null;

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: vPrimaryColor.withAlpha(40),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1) Title. If empty string, doesn't display.
                if (post.title.isNotEmpty) _buildCenteredTitle(),

                // 2) Post text, fixed height for up to 6 lines
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildFixedHeightText(context),
                ),
                const SizedBox(height: 4),

                // 3) Location (if any)
                if (post.locationAddress != null &&
                    post.locationAddress!.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildLocationRow(),
                  ),

                // Add spacer to push content to the center
                const Spacer(),

                // 4) Images row or "No images" indicator - centered vertically
                _buildImagesRow(context, navigationService),

                // Add spacer to center the images section
                const Spacer(),

                // 5) Show bottom status based on post type:
                if (post.postIdX != null && post.updatedAt != null)
                  _buildIconsRowPosted(engagement, ref)
                else if (post.scheduledAt != null)
                  _buildScheduledButton()
                else
                  _buildDraftIndicator(),
              ],
            ),
          ),

          // Add cancel button for scheduled posts only
          if (isScheduled)
            Positioned(
              top: 12,
              left: 16,
              child: InkWell(
                onTap: () =>
                    _showDeleteConfirmDialog(context, ref, navigationService),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          // Edit button
          if (isScheduled)
            Positioned(
              top: 12,
              right: 16,
              child: InkWell(
                onTap: () => _navigateToEditScheduledPost(
                    context, ref, navigationService),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_note,
                        size: 14,
                        color: vPrimaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'EDIT',
                        style: TextStyle(
                          color: vPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToEditScheduledPost(BuildContext context, WidgetRef ref,
      NavigationService navigationService) {
    // Navigate to CreatePostScreen with the post for editing
    navigationService.navigateToEditScheduledPost(context, post);
  }

  /// Shows a confirmation dialog for deleting a scheduled post
  Future<void> _showDeleteConfirmDialog(BuildContext context, WidgetRef ref,
      NavigationService navigationService) async {
    final result = await navigationService.showConfirmationDialog(
      context,
      'Cancel Scheduled Post',
      'Are you sure you want to cancel this scheduled post? This action cannot be undone.',
      cancelText: 'Keep',
      confirmText: 'Delete',
    );

    if (result && context.mounted) {
      // Use async/await properly with a function that returns Future
      unawaited(_deleteScheduledPost(context, ref, navigationService));
    }
  }

  Future<void> _refreshPostEngagement(WidgetRef ref) async {
    try {
      // Check if this post has a Twitter ID (postIdX)
      if (post.postIdX == null || post.postIdX!.isEmpty) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: const Text('Cannot refresh metrics for this post'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Show loading indicator
      ScaffoldMessenger.of(ref.context).showSnackBar(
        const SnackBar(
          content: Text('Refreshing metrics...'),
          duration: Duration(milliseconds: 800),
        ),
      );

      // Capture engagement before the refresh to check if there's a change
      final beforeRefresh = ref
          .read(postEngagementDataProvider)
          .engagementByPostId[post.postIdX!];

      // Refresh engagement for this specific post
      final result = await ref.read(refreshPostEngagementUseCaseProvider).call(
            params: RefreshPostEngagementParams(post.postIdX!),
          );

      // Force refresh the data in the provider to ensure we have the latest
      await ref.read(postEngagementDataProvider.notifier).fetchEngagementData();

      // Get the updated engagement data
      final afterRefresh = ref
          .read(postEngagementDataProvider)
          .engagementByPostId[post.postIdX!];

      // Determine if there was any change in the metrics
      bool hasChanges = false;
      if (beforeRefresh != null && afterRefresh != null) {
        hasChanges = (beforeRefresh.likes != afterRefresh.likes) ||
            (beforeRefresh.retweets != afterRefresh.retweets) ||
            (beforeRefresh.quotes != afterRefresh.quotes) ||
            (beforeRefresh.replies != afterRefresh.replies) ||
            (beforeRefresh.impressions != afterRefresh.impressions);
      }

      // Show appropriate message based on result and whether metrics changed
      if (result is DataSuccess) {
        if (hasChanges) {
          ScaffoldMessenger.of(ref.context).showSnackBar(
            SnackBar(
              content: const Text('Metrics updated successfully'),
              backgroundColor: vAccentColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(ref.context).showSnackBar(
            SnackBar(
              content: const Text('No new engagement metrics available'),
              backgroundColor: Colors.grey.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (result is DataFailed) {
        // Handle the null error case specifically
        if (result.error?.error == null) {
          ScaffoldMessenger.of(ref.context).showSnackBar(
            SnackBar(
              content:
                  const Text('No new engagement data available at this time'),
              backgroundColor: Colors.orange.shade300,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(ref.context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result.error?.error}'),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing metrics: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Deletes the scheduled post from both local DB and server
  Future<void> _deleteScheduledPost(BuildContext context, WidgetRef ref,
      NavigationService navigationService) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(vPrimaryColor),
        ),
      ),
    );

    try {
      // First get server post by local ID to get the server ID
      final serverPostResult =
          await ref.read(getServerPostByLocalIdUseCaseProvider).call(
                params: GetServerPostByLocalIdParams(post.postIdLocal),
              );

      if (serverPostResult is DataSuccess<PostEntity?> &&
          serverPostResult.data != null) {
        // We found the post on the server, now delete it using the server ID
        final serverPost = serverPostResult.data!;
        final serverId = serverPost
            .postIdLocal; // The server's internal ID, not the Twitter ID

        final serverResult =
            await ref.read(deleteServerPostUseCaseProvider).call(
                  params: DeleteServerPostParams(serverId),
                );

        if (serverResult is DataFailed) {
          // Just log error but continue with local deletion
          debugPrint(
              'Error deleting post from server: ${serverResult.error?.error}');
        }
      } else {
        // If we couldn't find the post on server, just log it
        debugPrint('Post not found on server or error getting server post');
      }

      // Then delete from local database
      final localResult = await ref.read(deletePostUseCaseProvider).call(
            params: DeletePostParams(post.postIdLocal),
          );

      // Hide loading dialog
      if (context.mounted) {
        navigationService.navigateBack(context);
      }

      if (localResult is DataSuccess) {
        // Refresh post lists
        ref.read(postRefreshProvider.notifier).refreshAll();

        // Show success message if context is still mounted
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Scheduled post cancelled successfully'),
              backgroundColor: vAccentColor,
            ),
          );
        }
      } else if (localResult is DataFailed && context.mounted) {
        // Show error if context is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${localResult.error?.error}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      // Hide loading dialog if there was an exception and context is still mounted
      if (context.mounted) {
        navigationService.navigateBack(context);

        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  //--------------------------------------------------------------------------
  // 1) Centered bold title
  //--------------------------------------------------------------------------
  /// Builds a centered title with the post's title text.
  Widget _buildCenteredTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(50, 6, 50, 6),
      child: Text(
        post.title,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: boldTextStyle(
          size: 14,
          color: vPrimaryColor.withAlpha(220),
        ),
      ),
    );
  }

  //--------------------------------------------------------------------------
  // 2) Post text with a fixed height for 6 lines
  //--------------------------------------------------------------------------
  /// Builds a fixed-height container for post content, showing up to 6 lines.
  Widget _buildFixedHeightText(BuildContext context) {
    const double lineHeightPx = 16.0;
    const double totalHeightPx = lineHeightPx * 6;

    return Container(
      width: double.infinity,
      height: totalHeightPx,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: vPrimaryColor.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        post.content,
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
        style: secondaryTextStyle(
          size: 13,
          color: vPrimaryColor.withAlpha(220),
        ),
      ),
    );
  }

  //--------------------------------------------------------------------------
  // 3) Location
  //--------------------------------------------------------------------------
  /// Builds a row showing the location icon and address.
  Widget _buildLocationRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.location_on, color: Colors.redAccent, size: 16),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            post.locationAddress!,
            style: secondaryTextStyle(
              color: Colors.redAccent,
              size: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  //--------------------------------------------------------------------------
  // 4) Images row
  //--------------------------------------------------------------------------
  /// Builds either:
  /// - A row of images if the post has images
  /// - A "No images" indicator with green outline if no images are present
  Widget _buildImagesRow(
      BuildContext context, NavigationService navigationService) {
    final images = post.localImagePaths;

    // If there are no images, show a placeholder with appropriate text
    if (images.isEmpty) {
      final isDraft = post.scheduledAt == null && post.updatedAt == null;
      final message = isDraft
          ? "No images added to this draft"
          : "No images selected for this post";

      return SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: vAccentColor,
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.image_not_supported_outlined,
                color: vAccentColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                message,
                style: secondaryTextStyle(
                  color: vAccentColor,
                  size: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // If the post has images, display them in a scrollable row
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: images.map((path) {
            return GestureDetector(
              onTap: () => _openFullScreen(
                  context, images, images.indexOf(path), navigationService),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: vPrimaryColor.withAlpha(77),
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(path), fit: BoxFit.cover),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Opens a full-screen view of the selected images, starting at [index].
  /// This view is read-only (cannot delete images).
  void _openFullScreen(BuildContext context, List<String> images, int index,
      NavigationService navigationService) {
    // Using NavigationService instead of direct Navigator
    navigationService.navigateToFullScreenImage(
      context,
      images,
      index,
      allowDeletion: false,
    );
  }

  //--------------------------------------------------------------------------
  // 5) Bottom status indicators
  //--------------------------------------------------------------------------
  /// Builds a row for posted posts showing post time and action icons.
  Widget _buildIconsRowPosted(PostEngagement? engagement, WidgetRef ref) {
    final iconColor = vPrimaryColor.withAlpha(120);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Posted X time ago" text
        Text(
          "Posted ${relativeTimeDescription(post.updatedAt!)}",
          style: secondaryTextStyle(color: vAccentColor, size: 12),
        ),

        const SizedBox(height: 4),

        // Engagement metrics row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _iconWithCount(Icons.chat_bubble_outline,
                engagement != null ? "${engagement.replies}" : "0", iconColor),
            _iconWithCount(
                Icons.repeat,
                engagement != null
                    ? "${engagement.retweets + engagement.quotes}"
                    : "0",
                iconColor),
            _iconWithCount(Icons.favorite_border,
                engagement != null ? "${engagement.likes}" : "0", iconColor),
            _iconWithCount(
                Icons.bar_chart_outlined,
                engagement != null ? "${engagement.impressions}" : "0",
                iconColor),
          ],
        ),

        const SizedBox(height: 8),

        // Centered refresh button
        Center(
          child: GestureDetector(
            onTap: () => _refreshPostEngagement(ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: vPrimaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: vPrimaryColor.withAlpha(50)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 14, color: vPrimaryColor),
                  const SizedBox(width: 4),
                  Text(
                    "Refresh",
                    style: TextStyle(
                      fontSize: 12,
                      color: vPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a green button showing the scheduled date/time.
  Widget _buildScheduledButton() {
    final scheduledTime = post.scheduledAt!;
    // Use the new localizeDateTime function
    final formattedTime = localizeDateTime(scheduledTime);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: vAccentColor.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        formattedTime,
        textAlign: TextAlign.center,
        style: boldTextStyle(
          color: Colors.white,
          size: 13,
        ),
      ),
    );
  }

  /// Builds a "Draft" indicator bar for draft posts.
  Widget _buildDraftIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: vAccentColor.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "Draft",
        textAlign: TextAlign.center,
        style: boldTextStyle(
          color: Colors.white,
          size: 13,
        ),
      ),
    );
  }

  /// Builds a single icon with an associated count text.
  Widget _iconWithCount(IconData icon, String count, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 2),
        Text(count, style: secondaryTextStyle(color: color, size: 12)),
      ],
    );
  }
}
