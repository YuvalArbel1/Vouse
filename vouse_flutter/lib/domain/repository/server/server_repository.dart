// lib/domain/repository/server/server_repository.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/domain/entities/server/post_status.dart';
import 'package:vouse_flutter/domain/entities/server/post_engagement.dart';
import 'package:vouse_flutter/domain/entities/secure_db/x_auth_tokens.dart';

/// Repository for interacting with our backend server.
///
/// Provides methods for post scheduling, Twitter account connection,
/// and engagement metrics retrieval.
abstract class ServerRepository {
  /// Create a new post on the server for scheduling
  Future<DataState<String>> schedulePost(PostEntity post);

  /// Get all posts for the current user
  Future<DataState<List<PostEntity>>> getServerPosts();

  /// Get a single post by server ID
  Future<DataState<PostEntity?>> getServerPost(String id);

  /// Get a post by its local ID
  Future<DataState<PostEntity?>> getServerPostByLocalId(String postIdLocal);

  /// Update a post on the server
  Future<DataState<PostEntity>> updateServerPost(String id, PostEntity post);

  /// Delete a post from the server
  Future<DataState<void>> deleteServerPost(String id);

  /// Get the status of a post from the server
  Future<DataState<PostStatus?>> getPostStatus(String postIdLocal);

  /// Connect Twitter account by sending OAuth tokens to server
  Future<DataState<void>> connectTwitter(
      String userId,
      XAuthTokens tokens,
      );

  /// Disconnect Twitter account from the server
  Future<DataState<void>> disconnectTwitter(String userId);

  /// Check if Twitter account is connected
  Future<DataState<bool>> isTwitterConnected(String userId);

  /// Verify Twitter tokens are valid
  Future<DataState<String?>> verifyTwitterTokens(String userId);

  /// Get metrics for all posts
  Future<DataState<List<PostEngagement>>> getAllEngagements();

  /// Get metrics for a specific post by Twitter ID
  Future<DataState<PostEngagement?>> getEngagement(String postIdX);

  /// Get metrics for a post by its local ID
  Future<DataState<PostEngagement?>> getEngagementByLocalId(String postIdLocal);

  /// Force refresh of metrics for a post
  Future<DataState<PostEngagement?>> refreshEngagement(String postIdX);

  /// Refresh metrics for a post by local ID
  Future<DataState<PostEngagement?>> refreshEngagementByLocalId(String postIdLocal);

  /// Refresh all engagement metrics
  Future<DataState<Map<String, dynamic>>> refreshAllEngagements();

  /// Batch refresh engagement metrics for multiple posts
  Future<DataState<Map<String, dynamic>>> refreshBatchEngagements(List<String> postIds);
}