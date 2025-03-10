// lib/data/repository/server/server_repository_impl.dart

import 'package:dio/dio.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/data/clients/server/server_api_client.dart';
import 'package:vouse_flutter/data/models/server/post_model.dart';
import 'package:vouse_flutter/data/models/server/engagement_model.dart';
import 'package:vouse_flutter/data/models/server/twitter_auth_model.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/domain/entities/server/post_status.dart';
import 'package:vouse_flutter/domain/entities/server/post_engagement.dart';
import 'package:vouse_flutter/domain/entities/secure_db/x_auth_tokens.dart';
import 'package:vouse_flutter/domain/repository/server/server_repository.dart';

/// Implementation of [ServerRepository] using Retrofit API client.
class ServerRepositoryImpl implements ServerRepository {
  final ServerApiClient _apiClient;

  /// Creates a [ServerRepositoryImpl] with the provided [ServerApiClient].
  ServerRepositoryImpl(this._apiClient);

  @override
  Future<DataState<String>> schedulePost(PostEntity post) async {
    try {
      final serverPostModel = ServerPostModel.fromPostEntity(post);
      final response = await _apiClient.createPost(serverPostModel);

      if (response.success && response.data != null) {
        return DataSuccess(response.data!.id ?? '');
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: response.message ?? 'Failed to schedule post',
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  @override
  Future<DataState<List<PostEntity>>> getServerPosts() async {
    try {
      final response = await _apiClient.getPosts();

      if (response.success && response.data != null) {
        final posts = response.data!
            .map((model) => model.toPostEntity())
            .toList();
        return DataSuccess(posts);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: response.message ?? 'Failed to get posts',
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  @override
  Future<DataState<PostEntity?>> getServerPost(String id) async {
    try {
      final response = await _apiClient.getPost(id);

      if (response.success && response.data != null) {
        return DataSuccess(response.data!.toPostEntity());
      } else if (response.success && response.data == null) {
        return const DataSuccess(null);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: response.message ?? 'Failed to get post',
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  @override
  Future<DataState<PostEntity?>> getServerPostByLocalId(
      String postIdLocal) async {
    try {
      final response = await _apiClient.getPostByLocalId(postIdLocal);

      if (response.success && response.data != null) {
        return DataSuccess(response.data!.toPostEntity());
      } else if (response.success && response.data == null) {
        return const DataSuccess(null);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: response.message ?? 'Failed to get post by local ID',
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  @override
  Future<DataState<PostEntity>> updateServerPost(String id,
      PostEntity post) async {
    try {
      final serverPostModel = ServerPostModel.fromPostEntity(post);
      final response = await _apiClient.updatePost(id, serverPostModel);

      if (response.success && response.data != null) {
        return DataSuccess(response.data!.toPostEntity());
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: response.message ?? 'Failed to update post',
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  @override
  Future<DataState<void>> deleteServerPost(String id) async {
    try {
      final response = await _apiClient.deletePost(id);

      if (response.success) {
        return const DataSuccess(null);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: response.message ?? 'Failed to delete post',
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  @override
  Future<DataState<PostStatus?>> getPostStatus(String postIdLocal) async {
    try {
      final response = await _apiClient.getPostByLocalId(postIdLocal);

      if (response.success && response.data != null &&
          response.data!.status != null) {
        final serverStatus = response.data!.status!;
        // Convert ServerPostStatus to domain PostStatus
        final postStatus = PostStatus.values.firstWhere(
              (element) => element.name == serverStatus.toValue(),
          orElse: () => PostStatus.draft,
        );
        return DataSuccess(postStatus);
      } else if (response.success) {
        return const DataSuccess(null);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: response.message ?? 'Failed to get post status',
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  @override
  Future<DataState<void>> connectTwitter(String userId,
      XAuthTokens tokens) async {
    try {
      final twitterAuthModel = TwitterAuthModel.fromXAuthTokens(tokens);
      final response = await _apiClient.connectTwitterAccount(
          userId, twitterAuthModel);

      if (response.success) {
        return const DataSuccess(null);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: response.message ?? 'Failed to connect Twitter account',
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  @override
  Future<DataState<void>> disconnectTwitter(String userId) async {
    try {
      final response = await _apiClient.disconnectTwitterAccount(userId);

      if (response.success) {
        return const DataSuccess(null);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: response.message ?? 'Failed to disconnect Twitter account',
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  @override
  Future<DataState<bool>> isTwitterConnected(String userId) async {
    try {
      final response = await _apiClient.checkTwitterStatus(userId);

      if (response.success && response.data != null) {
        final isConnected = response.data!['isConnected'] as bool? ?? false;
        return DataSuccess(isConnected);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: response.message ??
                'Failed to check Twitter connection status',
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  @override
  Future<DataState<String?>> verifyTwitterTokens(String userId) async {
    try {
      final response = await _apiClient.verifyTwitterTokens(userId);

      if (response.success && response.data != null) {
        final username = response.data!['username'] as String?;
        return DataSuccess(username);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: response.message ?? 'Failed to verify Twitter tokens',
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  @override
  Future<DataState<List<PostEngagement>>> getAllEngagements() async {
    try {
      final response = await _apiClient.getAllEngagements();

      if (response.success && response.data != null) {
        final engagements = response.data!.map((model) =>
            _mapToEngagementEntity(model)).toList();
        return DataSuccess(engagements);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: response.message ?? 'Failed to get engagements',
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  @override
  Future<DataState<PostEngagement?>> getEngagement(String postIdX) async {
    try {
      final response = await _apiClient.getEngagement(postIdX);

      if (response.success && response.data != null) {
        return DataSuccess(_mapToEngagementEntity(response.data!));
      } else if (response.success && response.data == null) {
        return const DataSuccess(null);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: response.message ?? 'Failed to get engagement',
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  @override
  Future<DataState<PostEngagement?>> getEngagementByLocalId(
      String postIdLocal) async {
    try {
      final response = await _apiClient.getEngagementByLocalId(postIdLocal);

      if (response.success && response.data != null) {
        return DataSuccess(_mapToEngagementEntity(response.data!));
      } else if (response.success && response.data == null) {
        return const DataSuccess(null);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: response.message ?? 'Failed to get engagement by local ID',
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  @override
  Future<DataState<PostEngagement?>> refreshEngagement(String postIdX) async {
    try {
      final response = await _apiClient.refreshEngagement(postIdX);

      if (response.success && response.data != null) {
        return DataSuccess(_mapToEngagementEntity(response.data!));
      } else if (response.success && response.data == null) {
        return const DataSuccess(null);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: response.message ?? 'Failed to refresh engagement',
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  @override
  Future<DataState<PostEngagement?>> refreshEngagementByLocalId(
      String postIdLocal) async {
    try {
      final response = await _apiClient.refreshEngagementByLocalId(postIdLocal);

      if (response.success && response.data != null) {
        return DataSuccess(_mapToEngagementEntity(response.data!));
      } else if (response.success && response.data == null) {
        return const DataSuccess(null);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: response.message ??
                'Failed to refresh engagement by local ID',
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  @override
  Future<DataState<Map<String, dynamic>>> refreshAllEngagements() async {
    try {
      final response = await _apiClient.refreshAllEngagements();

      if (response.success && response.data != null) {
        return DataSuccess(response.data!);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: response.message ?? 'Failed to refresh all engagements',
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  /// Maps a [PostEngagementModel] to a domain [PostEngagement] entity
  PostEngagement _mapToEngagementEntity(PostEngagementModel model) {
    // Convert hourly metrics to time points
    final timePoints = model.hourlyMetrics.map((hourly) {
      return EngagementTimePoint(
        timestamp: hourly.timestamp,
        likes: hourly.metrics['likes'] as int? ?? 0,
        retweets: hourly.metrics['retweets'] as int? ?? 0,
        quotes: hourly.metrics['quotes'] as int? ?? 0,
        replies: hourly.metrics['replies'] as int? ?? 0,
        impressions: hourly.metrics['impressions'] as int? ?? 0,
      );
    }).toList();

    return PostEngagement(
      postIdX: model.postIdX,
      postIdLocal: model.postIdLocal,
      likes: model.likes,
      retweets: model.retweets,
      quotes: model.quotes,
      replies: model.replies,
      impressions: model.impressions,
      timePoints: timePoints,
      createdAt: model.createdAt,
      lastUpdated: model.updatedAt,
    );
  }

  @override
  Future<DataState<Map<String, dynamic>>> refreshBatchEngagements(List<String> postIds) async {
    try {
      final response = await _apiClient.refreshBatchEngagements({
        'postIds': postIds,
      });

      if (response.success && response.data != null) {
        return DataSuccess(response.data!);
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: response.message ?? 'Failed to refresh batch engagements',
          ),
        );
      }
    } on DioException catch (e) {
      return DataFailed(e);
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }
}