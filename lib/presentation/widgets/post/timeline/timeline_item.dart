// lib/presentation/widgets/post/timeline/timeline_item.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vouse_flutter/core/util/colors.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/presentation/widgets/post/post_preview/post_card.dart';

/// A widget for displaying a post with timeline visualization.
///
/// Features:
/// - Timeline visualization with dot and connecting line
/// - Date badge with emoji based on time of day
/// - Status indicators (upcoming, past due)
/// - Full PostCard integration
class TimelinePostItem extends StatelessWidget {
  /// The post entity to display
  final PostEntity post;

  /// The index of this item
  final int index;

  /// Whether this is the last item in the timeline
  final bool isLast;

  /// Creates a [TimelinePostItem] widget.
  const TimelinePostItem({
    super.key,
    required this.post,
    required this.index,
    required this.isLast,
  });

  /// Returns an emoji based on the time of day
  String _getTimeEmoji(DateTime dateTime) {
    final hour = dateTime.hour;

    if (hour >= 5 && hour < 12) {
      return '🌅'; // Morning (sunrise)
    } else if (hour >= 12 && hour < 17) {
      return '☀️'; // Afternoon (sun)
    } else if (hour >= 17 && hour < 21) {
      return '🌆'; // Evening (sunset)
    } else {
      return '🌙'; // Night (moon)
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduledTime = post.scheduledAt!;
    final now = DateTime.now();

    // Calculate if post is scheduled for today, tomorrow, or later
    final isToday = scheduledTime.year == now.year &&
        scheduledTime.month == now.month &&
        scheduledTime.day == now.day;

    final isTomorrow = scheduledTime.year == now.year &&
        scheduledTime.month == now.month &&
        scheduledTime.day == now.day + 1;

    // Format the date for display
    final dateLabel = isToday
        ? 'Today'
        : isTomorrow
        ? 'Tomorrow'
        : DateFormat('EEE, MMM d').format(scheduledTime);

    // Format the time
    final timeLabel = DateFormat('h:mm a').format(scheduledTime);

    // Check if post is upcoming or past due
    final isPastDue = scheduledTime.isBefore(now);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline visualization
          Column(
            children: [
              // Time indicator dot
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPastDue ? Colors.grey : vAccentColor,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: (isPastDue ? Colors.grey : vAccentColor)
                          .withAlpha(100),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  isPastDue ? Icons.hourglass_empty : Icons.schedule,
                  color: Colors.white,
                  size: 14,
                ),
              ),

              // Connecting line (hide for last item)
              if (!isLast)
                Container(
                  width: 2,
                  height: 310, // Fixed height for consistency
                  color: vAccentColor, // Green accent color for timeline
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Post content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date/time header with emoji
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                    isPastDue ? Colors.grey.withAlpha(200) : vAccentColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (isPastDue ? Colors.grey : vAccentColor)
                            .withAlpha(50),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Add emoji based on time of day
                      Text(
                        _getTimeEmoji(scheduledTime),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isPastDue ? Icons.warning : Icons.access_time,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Post card
                SizedBox(
                  height: 300, // Fixed height for consistency
                  child: PostCard(post: post),
                ),

                if (!isLast) const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}