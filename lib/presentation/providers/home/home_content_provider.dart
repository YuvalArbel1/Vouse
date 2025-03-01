// lib/presentation/providers/home/home_content_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/presentation/providers/home/home_posts_providers.dart';

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
class HomeContentNotifier extends StateNotifier<HomeContentState> {
  final Ref _ref;

  /// Creates a home content notifier
  HomeContentNotifier(this._ref) : super(HomeContentState());

  /// Loads all home screen content
  Future<void> loadHomeContent() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User not logged in',
        );
        return;
      }

      // Load all post data
      await _loadAllPostData();

      // Update overall state
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
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

      // Get recent posts (most recent 5)
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
  Future<void> refreshHomeContent() async {
    // Invalidate post providers to force fresh data
    _ref.invalidate(postedPostsProvider);
    _ref.invalidate(scheduledPostsProvider);
    _ref.invalidate(draftPostsProvider);

    // Load all content again
    await loadHomeContent();
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
