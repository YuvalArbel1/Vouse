// lib/presentation/providers/home/home_content_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/presentation/providers/home/home_posts_providers.dart';

// Import refresh providers
import 'package:vouse_flutter/presentation/providers/post/post_refresh_provider.dart';

import '../server/server_sync_provider.dart';
import '../user/user_profile_provider.dart';
import '../engagement/post_engagement_provider.dart'; // Add this import

/// State for home screen content
class HomeContentState {
  /// Loading state for home content
  final bool isLoading;

  /// Error message if loading failed
  final String? errorMessage;

  /// Post counts by category (posted, scheduled, drafts)
  final Map<String, int> postCounts;

  /// Recent posts (top 5)
  final List<PostEntity> recentPosts;

  /// Upcoming scheduled posts (ordered by date)
  final List<PostEntity> upcomingPosts;

  /// Draft posts
  final List<PostEntity> draftPosts;

  /// Creates a home content state
  HomeContentState({
    this.isLoading = true,
    this.errorMessage,
    this.postCounts = const {'posted': 0, 'scheduled': 0, 'drafts': 0},
    this.recentPosts = const [],
    this.upcomingPosts = const [],
    this.draftPosts = const [],
  });

  /// Creates a copy of this state with the given fields replaced
  HomeContentState copyWith({
    bool? isLoading,
    String? errorMessage,
    Map<String, int>? postCounts,
    List<PostEntity>? recentPosts,
    List<PostEntity>? upcomingPosts,
    List<PostEntity>? draftPosts,
  }) {
    return HomeContentState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      postCounts: postCounts ?? this.postCounts,
      recentPosts: recentPosts ?? this.recentPosts,
      upcomingPosts: upcomingPosts ?? this.upcomingPosts,
      draftPosts: draftPosts ?? this.draftPosts,
    );
  }
}

/// A notifier that manages the home screen content
///
/// This class keeps track of all post types (posted, scheduled, drafts)
/// and automatically updates when refresh events are triggered.
class HomeContentNotifier extends StateNotifier<HomeContentState> {
  final Ref _ref;

  /// Flag to prevent multiple simultaneous refreshes
  bool _isRefreshing = false;

  /// Creates a home content notifier
  HomeContentNotifier(this._ref) : super(HomeContentState()) {
    // Listen for refresh events
    _ref.listen(postRefreshProvider, (previous, current) {
      if (previous != current) {
        refreshHomeContent();
      }
    });
  }

  /// Loads all initial data required for the home screen
  Future<void> loadHomeContent() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous refreshes

    state = state.copyWith(isLoading: true, errorMessage: null);
    _isRefreshing = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User not logged in',
        );
        _isRefreshing = false;
        return;
      }

      // Load all post data directly from providers
      await _loadAllPostData();

      // Update overall state
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    } finally {
      _isRefreshing = false;
    }
  }

  /// Loads all post data (posted, scheduled, drafts)
  Future<void> _loadAllPostData() async {
    try {
      // Get all post data from providers
      final postedPostsAsync = await _ref.read(postedPostsProvider.future);
      final scheduledPostsAsync =
      await _ref.read(scheduledPostsProvider.future);
      final draftPostsAsync = await _ref.read(draftPostsProvider.future);

      // Update post counts
      final postCounts = {
        'posted': postedPostsAsync.length,
        'scheduled': scheduledPostsAsync.length,
        'drafts': draftPostsAsync.length,
      };

      // Get recent posts (most recent 5) - use the existing sorting
      final sortedPosted = List<PostEntity>.from(postedPostsAsync)
        ..sort((a, b) =>
            (b.updatedAt ?? b.createdAt).compareTo(a.updatedAt ?? a.createdAt));
      final recentPosts = sortedPosted.take(5).toList();

      // Get upcoming posts (sorted by schedule date)
      final sortedScheduled = List<PostEntity>.from(scheduledPostsAsync)
        ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));

      // Update state with all post data
      state = state.copyWith(
        postCounts: postCounts,
        recentPosts: recentPosts,
        upcomingPosts: sortedScheduled,
        draftPosts: draftPostsAsync,
      );
    } catch (e) {
      // If an error occurs, maintain current data but set error message
      state = state.copyWith(
        errorMessage: 'Error loading posts: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// Refreshes home content by invalidating providers and reloading data
  ///
  /// This is a manual refresh method that can be triggered by the user
  /// to completely reload all post data.
  Future<void> refreshHomeContent() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous refreshes
    _isRefreshing = true;

    try {
      // First, synchronize with the server to update post statuses
      await _ref.read(serverSyncProvider.notifier).synchronizePosts();

      // Then refresh engagement data
      await _ref.read(postEngagementDataProvider.notifier).fetchEngagementData();

      // Then load user profile if needed
      if (_ref.read(userProfileProvider).loadingState !=
          UserProfileLoadingState.loading) {
        await _ref.read(userProfileProvider.notifier).loadUserProfile();
      }

      // Invalidate all post providers to force refetching
      _ref.invalidate(postedPostsProvider);
      _ref.invalidate(scheduledPostsProvider);
      _ref.invalidate(draftPostsProvider);

      // Reload all post data
      await _loadAllPostData();
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing home content: $e');
      }
    } finally {
      _isRefreshing = false;
    }
  }
}

/// Provider for the home content
final homeContentProvider =
StateNotifierProvider<HomeContentNotifier, HomeContentState>((ref) {
  return HomeContentNotifier(ref);
});

/// Provider for post statistics
final postStatsProvider = Provider<Map<String, int>>((ref) {
  return ref.watch(homeContentProvider).postCounts;
});

/// Provider for recent posts
final recentPostsProvider = Provider<List<PostEntity>>((ref) {
  return ref.watch(homeContentProvider).recentPosts;
});

/// Provider for upcoming posts
final upcomingPostsProvider = Provider<List<PostEntity>>((ref) {
  return ref.watch(homeContentProvider).upcomingPosts;
});

/// Provider for draft posts
final draftPostsListProvider = Provider<List<PostEntity>>((ref) {
  return ref.watch(homeContentProvider).draftPosts;
});