// lib/data/models/server/engagement_model.dart

/// Structure of hourly metrics data from the server
class HourlyMetric {
  final DateTime timestamp;
  final Map<String, dynamic> metrics;

  HourlyMetric({
    required this.timestamp,
    required this.metrics,
  });

  factory HourlyMetric.fromJson(Map<String, dynamic> json) {
    return HourlyMetric(
      timestamp: DateTime.parse(json['timestamp'] as String),
      metrics: json['metrics'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'metrics': metrics,
    };
  }
}

/// Model representing engagement metrics for a published post.
///
/// This tracks metrics like likes, retweets, replies, etc.
class PostEngagementModel {
  final String postIdX; // Twitter post ID
  final String postIdLocal; // Local post ID
  final int likes;
  final int retweets;
  final int quotes;
  final int replies;
  final int impressions;
  final List<HourlyMetric> hourlyMetrics;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostEngagementModel({
    required this.postIdX,
    required this.postIdLocal,
    this.likes = 0,
    this.retweets = 0,
    this.quotes = 0,
    this.replies = 0,
    this.impressions = 0,
    this.hourlyMetrics = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostEngagementModel.fromJson(Map<String, dynamic> json) {
    return PostEngagementModel(
      postIdX: json['postIdX'] as String,
      postIdLocal: json['postIdLocal'] as String,
      likes: json['likes'] as int? ?? 0,
      retweets: json['retweets'] as int? ?? 0,
      quotes: json['quotes'] as int? ?? 0,
      replies: json['replies'] as int? ?? 0,
      impressions: json['impressions'] as int? ?? 0,
      hourlyMetrics: json['hourlyMetrics'] != null
          ? (json['hourlyMetrics'] as List)
          .map((e) => HourlyMetric.fromJson(e as Map<String, dynamic>))
          .toList()
          : [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postIdX': postIdX,
      'postIdLocal': postIdLocal,
      'likes': likes,
      'retweets': retweets,
      'quotes': quotes,
      'replies': replies,
      'impressions': impressions,
      'hourlyMetrics': hourlyMetrics.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Total engagement (sum of likes, retweets, quotes, and replies)
  int get totalEngagement => likes + retweets + quotes + replies;

  /// Engagement rate (total engagement / impressions)
  double get engagementRate {
    if (impressions == 0) return 0;
    return totalEngagement / impressions;
  }
}