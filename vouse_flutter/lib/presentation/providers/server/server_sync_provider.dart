// lib/presentation/providers/server/server_sync_provider.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/domain/entities/server/post_engagement.dart';
import 'package:vouse_flutter/domain/usecases/post/save_post_usecase.dart';
import 'package:vouse_flutter/domain/usecases/server/get_post_engagements_usecase.dart';
import 'package:vouse_flutter/domain/usecases/server/get_server_posts_usecase.dart';
import 'package:vouse_flutter/presentation/providers/local_db/local_post_providers.dart';
import 'package:vouse_flutter/presentation/providers/post/post_refresh_provider.dart';
import 'package:vouse_flutter/presentation/providers/server/server_providers.dart';
import 'package:vouse_flutter/presentation/providers/engagement/post_engagement_provider.dart';

import '../../../domain/usecases/post/get_posts_by_user_usecase.dart';

/// Synchronization state for server-local data
enum SyncState {
  /// Initial state
  initial,

  /// Currently syncing
  syncing,

  /// Sync completed successfully
  completed,

  /// Sync failed
  error
}

/// State for the server sync provider
class ServerSyncState {
  final SyncState state;
  final String? errorMessage;
  final DateTime? lastSyncTime;
  final int postsUpdated;
  final int engagementsUpdated;

  ServerSyncState({
    this.state = SyncState.initial,
    this.errorMessage,
    this.lastSyncTime,
    this.postsUpdated = 0,
    this.engagementsUpdated = 0,
  });

  ServerSyncState copyWith({
    SyncState? state,
    String? errorMessage,
    DateTime? lastSyncTime,
    int? postsUpdated,
    int? engagementsUpdated,
  }) {
    return ServerSyncState(
      state: state ?? this.state,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      postsUpdated: postsUpdated ?? this.postsUpdated,
      engagementsUpdated: engagementsUpdated ?? this.engagementsUpdated,
    );
  }
}

/// A notifier that handles synchronization between server and local posts
class ServerSyncNotifier extends StateNotifier<ServerSyncState> {
  final GetServerPostsUseCase _getServerPostsUseCase;
  final GetPostEngagementsUseCase _getPostEngagementsUseCase;
  final SavePostUseCase _savePostUseCase;
  final Ref _ref;

  // Guard against multiple simultaneous syncs
  bool _isSyncing = false;

  /// Creates a [ServerSyncNotifier] with required use cases and ref
  ServerSyncNotifier({
    required GetServerPostsUseCase getServerPostsUseCase,
    required GetPostEngagementsUseCase getPostEngagementsUseCase,
    required SavePostUseCase savePostUseCase,
    required Ref ref,
  })  : _getServerPostsUseCase = getServerPostsUseCase,
        _getPostEngagementsUseCase = getPostEngagementsUseCase,
        _savePostUseCase = savePostUseCase,
        _ref = ref,
        super(ServerSyncState());

  /// Synchronizes posts between server and local storage.
  ///
  /// This method:
  /// 1. Checks if the user has any scheduled or published posts to avoid unnecessary API calls
  /// 2. Fetches all posts from the server for users with relevant posts
  /// 3. Updates local posts with server data (especially postIdX)
  /// 4. Moves scheduled posts that have been published to "posted" status
  /// 5. Updates engagement metrics for posted posts
  ///
  /// Returns true if synchronization was successful, false otherwise.
  Future<bool> synchronizePosts() async {
    // Guard against multiple simultaneous syncs
    if (_isSyncing) return false;
    _isSyncing = true;

    try {
      // Update state to syncing
      state = state.copyWith(
        state: SyncState.syncing,
        errorMessage: null,
      );

      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        state = state.copyWith(
          state: SyncState.error,
          errorMessage: 'No user logged in',
        );
        return false;
      }

      // First check if the user has any scheduled or published posts to avoid unnecessary API calls
      final getPostsUseCase = _ref.read(getPostsByUserUseCaseProvider);
      final localPostsResult =
          await getPostsUseCase.call(params: GetPostsByUserParams(user.uid));

      List<PostEntity> localPosts = [];
      bool hasScheduledPosts = false;
      bool hasPublishedPosts = false;

      if (localPostsResult is DataSuccess<List<PostEntity>>) {
        localPosts = localPostsResult.data!;

        // Check if user has any scheduled or published posts
        hasScheduledPosts = localPosts.any((p) =>
            p.scheduledAt != null && (p.postIdX == null || p.postIdX!.isEmpty));
        hasPublishedPosts =
            localPosts.any((p) => p.postIdX != null && p.postIdX!.isNotEmpty);

        // If no relevant posts, skip API calls to avoid rate limiting
        if (!hasScheduledPosts && !hasPublishedPosts) {
          debugPrint(
              'ServerSync: No scheduled or published posts found, skipping server sync');
          state = state.copyWith(
            state: SyncState.completed,
            lastSyncTime: DateTime.now(),
            postsUpdated: 0,
            engagementsUpdated: 0,
          );
          return true;
        }
      }

      // We have relevant posts, proceed with server sync

      // 1. Fetch all posts from server
      debugPrint('ServerSync: Fetching posts from server');
      final serverPostsResult = await _getServerPostsUseCase.call();

      if (serverPostsResult is DataFailed) {
        state = state.copyWith(
          state: SyncState.error,
          errorMessage:
              'Failed to fetch server posts: ${serverPostsResult.error?.error}',
        );
        return false;
      }

      // 2. Fetch engagement metrics only if user has published posts
      Map<String, PostEngagement> engagementMap = {};
      if (hasPublishedPosts) {
        debugPrint('ServerSync: Fetching engagement metrics');
        final engagementResult = await _getPostEngagementsUseCase.call();

        if (engagementResult is DataSuccess<List<PostEngagement>>) {
          // Create a map of postIdX -> engagement data for easy lookup
          for (final engagement in engagementResult.data!) {
            if (engagement.postIdX.isNotEmpty) {
              engagementMap[engagement.postIdX] = engagement;
            }

            // Also map by local ID for posts that don't have postIdX yet
            if (engagement.postIdLocal.isNotEmpty) {
              engagementMap[engagement.postIdLocal] = engagement;
            }
          }

          // Update the engagement provider with the new data
          _ref
              .read(postEngagementDataProvider.notifier)
              .updateEngagementData(engagementResult.data!);

          // Force refresh engagement metrics from Twitter API only if we have published posts
          await _ref
              .read(postEngagementDataProvider.notifier)
              .refreshAllEngagements();
        }
      } else {
        debugPrint(
            'ServerSync: No published posts, skipping engagement metrics fetch');
      }

      // Get the current time for comparing with scheduled posts
      final now = DateTime.now();

      // Count of posts and engagements that were updated
      int updatedPostsCount = 0;
      int updatedEngagementsCount = 0;

      // 3. Process server posts
      if (serverPostsResult is DataSuccess<List<PostEntity>>) {
        final serverPosts = serverPostsResult.data!;
        debugPrint('ServerSync: Processing ${serverPosts.length} server posts');

        for (final serverPost in serverPosts) {
          // Only process posts with a postIdX (published posts)
          if (serverPost.postIdX != null && serverPost.postIdX!.isNotEmpty) {
            // Find matching local post by postIdLocal
            final matchingLocalPost = localPosts.firstWhere(
              (p) => p.postIdLocal == serverPost.postIdLocal,
              orElse: () => serverPost, // Use server post if no local match
            );

            // Check if this post needs to be updated
            if (matchingLocalPost.postIdX == null ||
                matchingLocalPost.postIdX != serverPost.postIdX) {
              // This post was scheduled and now has a postIdX, it should be "posted"
              final updatedPost = matchingLocalPost.copyWith(
                postIdX: serverPost.postIdX,
                updatedAt: DateTime.now(),
                // Keep other fields from the local post if available
              );

              debugPrint(
                  'ServerSync: Updating post ${updatedPost.postIdLocal} with postIdX ${updatedPost.postIdX}');

              // Save the updated post
              await _savePostUseCase.call(
                params: SavePostParams(updatedPost, user.uid),
              );

              updatedPostsCount++;
            }
          }
        }
      }

      // 4. Check for scheduled posts with past dates that should be considered published
      for (final localPost in localPosts) {
        // Check if this is a scheduled post whose time has passed but doesn't have a postIdX
        if (localPost.scheduledAt != null &&
            localPost.scheduledAt!.isBefore(now) &&
            (localPost.postIdX == null || localPost.postIdX!.isEmpty)) {
          // Find this post in engagement data by local ID
          final engagement = engagementMap[localPost.postIdLocal];

          if (engagement != null && engagement.postIdX.isNotEmpty) {
            // We have engagement data with a postIdX, update the local post
            final updatedPost = localPost.copyWith(
              postIdX: engagement.postIdX,
              updatedAt: DateTime.now(),
            );

            debugPrint(
                'ServerSync: Updating past scheduled post ${updatedPost.postIdLocal} with postIdX ${updatedPost.postIdX}');

            // Save the updated post
            await _savePostUseCase.call(
              params: SavePostParams(updatedPost, user.uid),
            );

            updatedPostsCount++;
          }
        }
      }

      // Update engagement count
      if (hasPublishedPosts) {
        updatedEngagementsCount = engagementMap.length;
      }

      // Refresh all posts in providers to get the updated data
      _ref.read(postRefreshProvider.notifier).refreshAll();

      // Update state
      state = state.copyWith(
        state: SyncState.completed,
        lastSyncTime: DateTime.now(),
        postsUpdated: updatedPostsCount,
        engagementsUpdated: updatedEngagementsCount,
      );

      debugPrint(
          'ServerSync: Completed, updated $updatedPostsCount posts, $updatedEngagementsCount engagements');
      return true;
    } catch (e) {
      debugPrint('ServerSync: Error during sync: $e');
      state = state.copyWith(
        state: SyncState.error,
        errorMessage: 'Error during sync: $e',
      );
      return false;
    } finally {
      _isSyncing = false;
    }
  }
}

/// Provider for server sync operations
final serverSyncProvider =
    StateNotifierProvider<ServerSyncNotifier, ServerSyncState>((ref) {
  return ServerSyncNotifier(
    getServerPostsUseCase: ref.watch(getServerPostsUseCaseProvider),
    getPostEngagementsUseCase: ref.watch(getPostEngagementsUseCaseProvider),
    savePostUseCase: ref.watch(savePostUseCaseProvider),
    ref: ref,
  );
});

/// Provider for triggering sync operations
final syncServerPostsProvider = FutureProvider.autoDispose<bool>((ref) async {
  return ref.read(serverSyncProvider.notifier).synchronizePosts();
});
