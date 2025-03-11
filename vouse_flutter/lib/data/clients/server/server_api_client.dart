// lib/data/clients/server/server_api_client.dart

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:vouse_flutter/data/models/server/post_model.dart';
import 'package:vouse_flutter/data/models/server/engagement_model.dart';
import 'package:vouse_flutter/data/models/server/twitter_auth_model.dart';
import 'package:vouse_flutter/data/models/server/response_wrapper.dart';

part 'server_api_client.g.dart';

/// A Retrofit client for the Vouse server API.
///
/// This handles all direct communications with our backend server,
/// including post scheduling, Twitter account connection, and metrics retrieval.
@RestApi()
abstract class ServerApiClient {
  factory ServerApiClient(Dio dio, {String baseUrl}) = _ServerApiClient;

  // Posts endpoints

  /// Create a new post on the server for scheduling
  @POST('/posts')
  Future<ResponseWrapper<ServerPostModel>> createPost(
    @Body() ServerPostModel post,
  );

  /// Get all posts for the current user
  @GET('/posts')
  Future<ResponseWrapper<List<ServerPostModel>>> getPosts();

  /// Get a single post by server ID
  @GET('/posts/{id}')
  Future<ResponseWrapper<ServerPostModel>> getPost(
    @Path('id') String id,
  );

  /// Get a post by its local ID from the app
  @GET('/posts/local/{postIdLocal}')
  Future<ResponseWrapper<ServerPostModel>> getPostByLocalId(
    @Path('postIdLocal') String postIdLocal,
  );

  /// Update a post
  @PATCH('/posts/{id}')
  Future<ResponseWrapper<ServerPostModel>> updatePost(
    @Path('id') String id,
    @Body() ServerPostModel post,
  );

  /// Delete a post
  @DELETE('/posts/{id}')
  Future<ResponseWrapper<void>> deletePost(
    @Path('id') String id,
  );

  // Twitter Auth endpoints

  /// Connect a Twitter account by storing OAuth tokens
  @POST('/x/auth/{userId}/connect')
  Future<ResponseWrapper<void>> connectTwitterAccount(
    @Path('userId') String userId,
    @Body() TwitterAuthModel tokens,
  );

  /// Disconnect Twitter account
  @DELETE('/x/auth/{userId}/disconnect')
  Future<ResponseWrapper<void>> disconnectTwitterAccount(
    @Path('userId') String userId,
  );

  /// Check Twitter connection status
  @GET('/x/auth/{userId}/status')
  Future<ResponseWrapper<Map<String, dynamic>>> checkTwitterStatus(
    @Path('userId') String userId,
  );

  /// Verify Twitter tokens are valid
  @POST('/x/auth/{userId}/verify')
  Future<ResponseWrapper<Map<String, dynamic>>> verifyTwitterTokens(
    @Path('userId') String userId,
  );

  // Engagement endpoints

  /// Get engagement metrics for all posts
  @GET('/engagements')
  Future<ResponseWrapper<List<PostEngagementModel>>> getAllEngagements();

  /// Get engagement for a specific post by Twitter ID
  @GET('/engagements/{postIdX}')
  Future<ResponseWrapper<PostEngagementModel>> getEngagement(
    @Path('postIdX') String postIdX,
  );

  /// Get engagement by local post ID
  @GET('/engagements/local/{postIdLocal}')
  Future<ResponseWrapper<PostEngagementModel>> getEngagementByLocalId(
    @Path('postIdLocal') String postIdLocal,
  );

  /// Force refresh of engagement metrics for a post
  @POST('/engagements/refresh/{postIdX}')
  Future<ResponseWrapper<PostEngagementModel>> refreshEngagement(
    @Path('postIdX') String postIdX,
  );

  /// Refresh metrics for a post by local ID
  @POST('/engagements/refresh/local/{postIdLocal}')
  Future<ResponseWrapper<PostEngagementModel>> refreshEngagementByLocalId(
    @Path('postIdLocal') String postIdLocal,
  );

  /// Refresh all engagement metrics
  @POST('/engagements/refreshall')
  Future<ResponseWrapper<Map<String, dynamic>>> refreshAllEngagements();

  /// Batch refresh multiple posts' engagement metrics
  @POST('/engagements/refresh/batch')
  Future<ResponseWrapper<Map<String, dynamic>>> refreshBatchEngagements(
    @Body() Map<String, List<String>> postIds,
  );

  /// Register device token for push notifications
  @POST('/notifications/{userId}/register')
  Future<ResponseWrapper<void>> registerDeviceToken(
    @Path('userId') String userId,
    @Body() Map<String, dynamic> data,
  );

  /// Unregister device token
  @DELETE('/notifications/{userId}/tokens/{token}')
  Future<ResponseWrapper<void>> unregisterDeviceToken(
    @Path('userId') String userId,
    @Path('token') String token,
  );
}
