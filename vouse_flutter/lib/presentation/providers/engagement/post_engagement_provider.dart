// lib/presentation/providers/engagement/post_engagement_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/entities/server/post_engagement.dart';
import 'package:vouse_flutter/domain/usecases/server/get_post_engagements_usecase.dart';
import 'package:vouse_flutter/domain/usecases/server/refresh_all_engagements_usecase.dart';
import 'package:vouse_flutter/presentation/providers/server/server_providers.dart';

/// State for the post engagement data provider
class PostEngagementState {
  /// Map of postIdX to engagement data
  final Map<String, PostEngagement> engagementByPostId;

  /// Map of postIdLocal to engagement data
  final Map<String, PostEngagement> engagementByLocalId;

  /// Whether the data is currently loading
  final bool isLoading;

  /// Error message if loading failed
  final String? errorMessage;

  /// Last time the data was refreshed
  final DateTime? lastRefreshedAt;

  PostEngagementState({
    this.engagementByPostId = const {},
    this.engagementByLocalId = const {},
    this.isLoading = false,
    this.errorMessage,
    this.lastRefreshedAt,
  });

  PostEngagementState copyWith({
    Map<String, PostEngagement>? engagementByPostId,
    Map<String, PostEngagement>? engagementByLocalId,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastRefreshedAt,
  }) {
    return PostEngagementState(
      engagementByPostId: engagementByPostId ?? this.engagementByPostId,
      engagementByLocalId: engagementByLocalId ?? this.engagementByLocalId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
    );
  }

  /// Get total metrics across all posts
  Map<String, int> getTotalMetrics() {
    final metrics = {
      'Likes': 0,
      'Comments': 0,
      'Reposts': 0,
      'Impressions': 0,
    };

    for (final engagement in engagementByPostId.values) {
      metrics['Likes'] = (metrics['Likes'] ?? 0) + engagement.likes;
      metrics['Comments'] = (metrics['Comments'] ?? 0) + engagement.replies;
      metrics['Reposts'] =
          (metrics['Reposts'] ?? 0) + engagement.retweets + engagement.quotes;
      metrics['Impressions'] =
          (metrics['Impressions'] ?? 0) + engagement.impressions;
    }

    return metrics;
  }
}

/// Notifier for post engagement data
class PostEngagementNotifier extends StateNotifier<PostEngagementState> {
  final GetPostEngagementsUseCase _getPostEngagementsUseCase;
  final RefreshAllEngagementsUseCase _refreshAllEngagementsUseCase;
  final Ref _ref;

  /// Whether a refresh operation is in progress
  bool _isRefreshing = false;

  PostEngagementNotifier({
    required GetPostEngagementsUseCase getPostEngagementsUseCase,
    required RefreshAllEngagementsUseCase refreshAllEngagementsUseCase,
    required Ref ref,
  })  : _getPostEngagementsUseCase = getPostEngagementsUseCase,
        _refreshAllEngagementsUseCase = refreshAllEngagementsUseCase,
        _ref = ref,
        super(PostEngagementState());

  /// Updates the engagement data with a new list of engagements
  void updateEngagementData(List<PostEngagement> engagements) {
    final Map<String, PostEngagement> byPostId = {};
    final Map<String, PostEngagement> byLocalId = {};

    for (final engagement in engagements) {
      // Always map by postIdX (Twitter ID)
      if (engagement.postIdX.isNotEmpty) {
        byPostId[engagement.postIdX] = engagement;
      }

      // Also map by local ID for easier lookup
      if (engagement.postIdLocal.isNotEmpty) {
        byLocalId[engagement.postIdLocal] = engagement;
      }
    }

    state = state.copyWith(
      engagementByPostId: byPostId,
      engagementByLocalId: byLocalId,
      lastRefreshedAt: DateTime.now(),
    );
  }

  /// Fetches all engagement data from the server
  Future<bool> fetchEngagementData() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final result = await _getPostEngagementsUseCase.call();

      if (result is DataSuccess<List<PostEngagement>>) {
        updateEngagementData(result.data!);
        state = state.copyWith(isLoading: false);
        return true;
      } else if (result is DataFailed) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.error?.error.toString() ?? 'Unknown error',
        );
        return false;
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Refreshes engagements for multiple posts at once
  Future<bool> refreshBatchEngagements(List<String> postIds) async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final repository = _ref.read(serverRepositoryProvider);
      final result = await repository.refreshBatchEngagements(postIds);

      if (result is DataSuccess<Map<String, dynamic>>) {
        // After forcing a batch refresh, fetch the updated data
        await fetchEngagementData();
        return true;
      } else if (result is DataFailed) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.error?.error.toString() ?? 'Unknown error',
        );
        return false;
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Refreshes engagement for a specific post by ID
  Future<void> refreshEngagement(String postIdX) async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      state = state.copyWith(isLoading: true);

      // For now, just refresh all engagements
      // In the future, you can implement a specific post refresh when you add that endpoint
      await refreshAllEngagements();
    } catch (e) {
      // Handle error
      if (kDebugMode) {
        print('Error refreshing engagement: $e');
      }
    } finally {
      _isRefreshing = false;
    }
  }

  /// Forces a refresh of all engagement data from the server
  Future<bool> refreshAllEngagements() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final result = await _refreshAllEngagementsUseCase.call();

      if (result is DataSuccess<Map<String, dynamic>>) {
        // After forcing a refresh, fetch the updated data
        await fetchEngagementData();
        return true;
      } else if (result is DataFailed) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.error?.error.toString() ?? 'Unknown error',
        );
        return false;
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Gets engagement data for a specific post by Twitter ID
  PostEngagement? getEngagementByPostId(String postIdX) {
    return state.engagementByPostId[postIdX];
  }

  /// Gets engagement data for a specific post by local ID
  PostEngagement? getEngagementByLocalId(String postIdLocal) {
    return state.engagementByLocalId[postIdLocal];
  }

  /// Gets aggregated total metrics across all posts
  Map<String, int> getTotalMetrics() {
    return state.getTotalMetrics();
  }
}

/// Provider for post engagement data
final postEngagementDataProvider =
    StateNotifierProvider<PostEngagementNotifier, PostEngagementState>((ref) {
  return PostEngagementNotifier(
    getPostEngagementsUseCase: ref.watch(getPostEngagementsUseCaseProvider),
    refreshAllEngagementsUseCase:
        ref.watch(refreshAllEngagementsUseCaseProvider),
    ref: ref,
  );
});

/// Provider for total engagement counts across all posts
final totalEngagementProvider = Provider<Map<String, int>>((ref) {
  final engagementState = ref.watch(postEngagementDataProvider);
  return engagementState.getTotalMetrics();
});

/// Provider for checking if engagement data is currently loading
final isEngagementLoadingProvider = Provider<bool>((ref) {
  return ref.watch(postEngagementDataProvider).isLoading;
});

/// Provider that returns the count of posts with engagement data
final postsWithEngagementCountProvider = Provider<int>((ref) {
  return ref.watch(postEngagementDataProvider).engagementByPostId.length;
});
