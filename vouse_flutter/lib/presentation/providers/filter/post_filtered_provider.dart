// lib/presentation/providers/post/post_filtered_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/presentation/providers/home/home_posts_providers.dart';

/// Provider for active time filter
final activeTimeFilterProvider = StateProvider<String>((ref) => 'All Time');

/// Provider for filtering posts based on selected time filter
final filteredPostsProvider = Provider<AsyncValue<List<PostEntity>>>((ref) {
  final activeFilter = ref.watch(activeTimeFilterProvider);
  final postedPostsAsync = ref.watch(postedPostsProvider);

  return postedPostsAsync.when(
    data: (posts) {
      if (posts.isEmpty) {
        return AsyncValue.data([]);
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      List<PostEntity> filtered;

      // Filter posts based on the selected timeframe
      switch (activeFilter) {
        case 'Today':
          filtered = posts.where((post) {
            return post.updatedAt != null &&
                (DateTime(post.updatedAt!.year, post.updatedAt!.month, post.updatedAt!.day)
                    .isAtSameMomentAs(today));
          }).toList();
          break;

        case 'This Week':
          filtered = posts.where((post) {
            return post.updatedAt != null &&
                post.updatedAt!.isAfter(weekStart.subtract(const Duration(seconds: 1)));
          }).toList();
          break;

        case 'This Month':
          filtered = posts.where((post) {
            return post.updatedAt != null &&
                post.updatedAt!.isAfter(monthStart.subtract(const Duration(seconds: 1)));
          }).toList();
          break;

        case 'All Time':
        default:
          filtered = List.from(posts);
          break;
      }

      // Sort by updated time, newest first
      filtered.sort((a, b) =>
          (b.updatedAt ?? b.createdAt).compareTo(a.updatedAt ?? a.createdAt));

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Provider for engagement metrics
final engagementMetricsProvider = Provider<Map<String, int>>((ref) {
  final filteredPostsAsync = ref.watch(filteredPostsProvider);

  return filteredPostsAsync.when(
    data: (posts) {
      final metrics = {
        'Likes': 0,
        'Comments': 0,
        'Reposts': 0,
        'Impressions': 0,
      };

      if (posts.isEmpty) {
        return metrics;
      }

      // Calculate metrics based on post count (mock values)
      final postCount = posts.length;
      metrics['Likes'] = (postCount * 12.5).round();
      metrics['Comments'] = (postCount * 3.2).round();
      metrics['Reposts'] = (postCount * 2.7).round();
      metrics['Impressions'] = (postCount * 84.3).round();

      return metrics;
    },
    loading: () => {
      'Likes': 0,
      'Comments': 0,
      'Reposts': 0,
      'Impressions': 0,
    },
    error: (_, __) => {
      'Likes': 0,
      'Comments': 0,
      'Reposts': 0,
      'Impressions': 0,
    },
  );
});