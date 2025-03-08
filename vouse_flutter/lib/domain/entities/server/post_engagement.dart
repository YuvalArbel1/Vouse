// lib/domain/entities/server/post_engagement.dart

/// Data point representing metrics at a specific time
class EngagementTimePoint {
  final DateTime timestamp;
  final int likes;
  final int retweets;
  final int quotes;
  final int replies;
  final int impressions;

  /// Total engagement (sum of likes, retweets, quotes, and replies)
  int get totalEngagement => likes + retweets + quotes + replies;

  /// Engagement rate (total engagement / impressions)
  double get engagementRate {
    if (impressions == 0) return 0;
    return totalEngagement / impressions;
  }

  EngagementTimePoint({
    required this.timestamp,
    required this.likes,
    required this.retweets,
    required this.quotes,
    required this.replies,
    required this.impressions,
  });
}

/// Engagement metrics for a post, including time-series data for trends.
class PostEngagement {
  final String postIdX;
  final String postIdLocal;
  final int likes;
  final int retweets;
  final int quotes;
  final int replies;
  final int impressions;
  final List<EngagementTimePoint> timePoints;
  final DateTime createdAt;
  final DateTime lastUpdated;

  PostEngagement({
    required this.postIdX,
    required this.postIdLocal,
    required this.likes,
    required this.retweets,
    required this.quotes,
    required this.replies,
    required this.impressions,
    required this.timePoints,
    required this.createdAt,
    required this.lastUpdated,
  });

  /// Total engagement (sum of likes, retweets, quotes, and replies)
  int get totalEngagement => likes + retweets + quotes + replies;

  /// Engagement rate (total engagement / impressions)
  double get engagementRate {
    if (impressions == 0) return 0;
    return totalEngagement / impressions;
  }

  /// Engagement growth in the last time period (percentage)
  double get recentGrowthRate {
    if (timePoints.length < 2) return 0;

    final newest = timePoints.last;
    final previous = timePoints[timePoints.length - 2];

    if (previous.totalEngagement == 0) return 0;

    return ((newest.totalEngagement - previous.totalEngagement) /
        previous.totalEngagement) * 100;
  }
}