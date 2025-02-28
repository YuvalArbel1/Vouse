// lib/presentation/widgets/post_history/upcoming_posts_header.dart

import 'package:flutter/material.dart';
import 'package:vouse_flutter/core/util/colors.dart';

/// A comprehensive, dynamic header for upcoming posts screen
///
/// Features:
/// - Engaging storytelling through emoji and text
/// - Performance and progress indicators
/// - Responsive and adaptive design
/// - Visual representation of content scheduling journey
class UpcomingPostsHeader extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10), // Slight edge adjustment
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            vAccentColor,
            vAccentColor.withAlpha(200)
          ],
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
          _buildStatisticsSection(),
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
  Widget _buildStatisticsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatChip('🗓️ Scheduled', scheduledPostCount.toString()),
        _buildStatChip('⏰ Next in', _calculateNextPostTime()),
        _buildStatChip('📅 Coverage', '${_calculateScheduleCoverage()}d'),
      ],
    );
  }

  /// Calculate time to next scheduled post (mock implementation)
  String _calculateNextPostTime() {
    // This would ideally come from actual scheduled post data
    return scheduledPostCount > 0 ? '3d 12h' : 'N/A';
  }

  /// Calculate scheduling coverage (mock implementation)
  String _calculateScheduleCoverage() {
    // Mocked calculation of scheduling coverage
    return (scheduledPostCount * 2).toString();
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