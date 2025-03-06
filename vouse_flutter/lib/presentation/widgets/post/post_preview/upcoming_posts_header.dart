// lib/presentation/widgets/post/post_preview/upcoming_posts_header.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/presentation/providers/home/home_posts_providers.dart';

/// A comprehensive, dynamic header for upcoming posts screen
///
/// Features:
/// - Engaging storytelling through emoji and text
/// - Performance and progress indicators
/// - Responsive and adaptive design
/// - Visual representation of content scheduling journey
class UpcomingPostsHeader extends ConsumerWidget {
  /// Total number of scheduled posts
  final int scheduledPostCount;

  const UpcomingPostsHeader({
    super.key,
    required this.scheduledPostCount,
  });

  /// Dynamically select an emoji based on scheduled post count
  String _getPreparationEmoji() {
    if (scheduledPostCount == 0) return '🌱';
    if (scheduledPostCount < 3) return '🌿';
    if (scheduledPostCount < 10) return '🌳';
    return '🌲';
  }

  /// Generate an inspirational scheduling message
  String _getSchedulingStatus() {
    if (scheduledPostCount == 0) return 'No posts scheduled yet!';
    if (scheduledPostCount < 3) return 'Your content strategy is taking shape';
    if (scheduledPostCount < 10) return 'Building a consistent posting routine';
    return 'Master of content scheduling';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [vAccentColor, vAccentColor.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          _buildContentSection(),
          const SizedBox(height: 16),
          _buildStatisticsSection(ref),
        ],
      ),
    );
  }

  /// Build content journey section
  Widget _buildContentSection() {
    return Row(
      children: [
        // Schedule Icon
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white,
          child: Icon(Icons.schedule, color: vAccentColor, size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getPreparationEmoji()} Content Preparation',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getSchedulingStatus(),
                style: TextStyle(
                  color: Colors.white.withAlpha(204),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build statistics and progress section
  Widget _buildStatisticsSection(WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatChip('🗓️ Scheduled', scheduledPostCount.toString()),
        _buildStatChip('⏰ Next in', _calculateNextPostTime(ref)),
      ],
    );
  }

  /// Calculate time to nearest scheduled post
  String _calculateNextPostTime(WidgetRef ref) {
    if (scheduledPostCount <= 0) {
      return 'N/A';
    }

    // Get all scheduled posts
    final scheduledPostsAsync = ref.watch(scheduledPostsProvider);

    return scheduledPostsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return 'N/A';
        }

        // Sort posts by scheduledAt time (ensure not null and closest first)
        final sortedPosts = [...posts]
          ..removeWhere((post) => post.scheduledAt == null)
          ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));

        if (sortedPosts.isEmpty) {
          return 'N/A';
        }

        // Get the closest scheduled post
        final now = DateTime.now();
        final nextPost = sortedPosts.first;
        final nextDateTime = nextPost.scheduledAt!;

        // If post is in the past, return "Now"
        if (nextDateTime.isBefore(now)) {
          return 'Now';
        }

        // Calculate difference
        final difference = nextDateTime.difference(now);

        // Format the time difference
        if (difference.inDays > 0) {
          return '${difference.inDays}d ${(difference.inHours % 24)}h';
        } else if (difference.inHours > 0) {
          return '${difference.inHours}h ${(difference.inMinutes % 60)}m';
        } else if (difference.inMinutes > 0) {
          return '${difference.inMinutes}m';
        } else {
          return 'Now';
        }
      },
      loading: () => '...',
      error: (_, __) => 'Error',
    );
  }

  /// Create a styled statistic chip
  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(204),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
