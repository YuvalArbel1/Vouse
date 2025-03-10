// lib/presentation/providers/server/server_providers.dart

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/data/clients/server/server_api_client.dart';
import 'package:vouse_flutter/data/repository/server/server_repository_impl.dart';
import 'package:vouse_flutter/domain/repository/server/server_repository.dart';
import 'package:vouse_flutter/domain/usecases/server/check_twitter_status_usecase.dart';
import 'package:vouse_flutter/domain/usecases/server/connect_twitter_usecase.dart';
import 'package:vouse_flutter/domain/usecases/server/disconnect_twitter_usecase.dart';
import 'package:vouse_flutter/domain/usecases/server/get_post_engagement_by_local_id_usecase.dart';
import 'package:vouse_flutter/domain/usecases/server/get_post_engagement_usecase.dart';
import 'package:vouse_flutter/domain/usecases/server/get_post_engagements_usecase.dart';
import 'package:vouse_flutter/domain/usecases/server/get_server_posts_usecase.dart';
import 'package:vouse_flutter/domain/usecases/server/refresh_all_engagements_usecase.dart';
import 'package:vouse_flutter/domain/usecases/server/refresh_post_engagement_by_local_id_usecase.dart';
import 'package:vouse_flutter/domain/usecases/server/refresh_post_engagement_usecase.dart';
import 'package:vouse_flutter/domain/usecases/server/schedule_post_usecase.dart';
import 'package:vouse_flutter/domain/usecases/server/verify_twitter_tokens_usecase.dart';

import '../../../domain/usecases/server/delete_server_post_usecase.dart';
import '../../../domain/usecases/server/get_server_post_by_local_id_usecase.dart';
import '../../../domain/usecases/server/refresh_batch_engagements_usecase.dart';

/// Expose server URL as a provider so it can be accessed from other files
// In lib/presentation/providers/server/server_providers.dart
final serverUrlProvider = Provider<String>((ref) {
  return 'https://d1b6-2a0d-6fc0-ecf-bb00-9841-7514-c7cc-2eac.ngrok-free.app';
});

/// Dio provider for server API client with auth token interceptor
final dioProvider = Provider<Dio>((ref) {
  final serverUrl = ref.watch(serverUrlProvider);
  final dio = Dio(BaseOptions(
    baseUrl: serverUrl,
    connectTimeout: const Duration(milliseconds: 15000),
    receiveTimeout: const Duration(milliseconds: 15000),
  ));

  // Add auth token interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Get the Firebase ID token
        try {
          final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
          if (idToken != null) {
            options.headers['Authorization'] = 'Bearer $idToken';
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error getting Firebase token: $e');
          }
        }
        return handler.next(options);
      },
    ),
  );

  return dio;
});

/// Server API client provider
final serverApiClientProvider = Provider<ServerApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  final serverUrl = ref.watch(serverUrlProvider);
  return ServerApiClient(dio, baseUrl: serverUrl);
});

/// Server repository provider
final serverRepositoryProvider = Provider<ServerRepository>((ref) {
  final apiClient = ref.watch(serverApiClientProvider);
  return ServerRepositoryImpl(apiClient);
});

// Use case providers

/// Schedule post use case provider
final schedulePostUseCaseProvider = Provider<SchedulePostUseCase>((ref) {
  final repository = ref.watch(serverRepositoryProvider);
  return SchedulePostUseCase(repository);
});

/// Get server posts use case provider
final getServerPostsUseCaseProvider = Provider<GetServerPostsUseCase>((ref) {
  final repository = ref.watch(serverRepositoryProvider);
  return GetServerPostsUseCase(repository);
});

/// Connect Twitter use case provider
final connectTwitterUseCaseProvider = Provider<ConnectTwitterUseCase>((ref) {
  final repository = ref.watch(serverRepositoryProvider);
  return ConnectTwitterUseCase(repository);
});

/// Disconnect Twitter use case provider
final disconnectTwitterUseCaseProvider =
    Provider<DisconnectTwitterUseCase>((ref) {
  final repository = ref.watch(serverRepositoryProvider);
  return DisconnectTwitterUseCase(repository);
});

/// Check Twitter status use case provider
final checkTwitterStatusUseCaseProvider =
    Provider<CheckTwitterStatusUseCase>((ref) {
  final repository = ref.watch(serverRepositoryProvider);
  return CheckTwitterStatusUseCase(repository);
});

/// Verify Twitter tokens use case provider
final verifyTwitterTokensUseCaseProvider =
    Provider<VerifyTwitterTokensUseCase>((ref) {
  final repository = ref.watch(serverRepositoryProvider);
  return VerifyTwitterTokensUseCase(repository);
});

// Engagement providers (for later use)

/// Get post engagements use case provider
final getPostEngagementsUseCaseProvider =
    Provider<GetPostEngagementsUseCase>((ref) {
  final repository = ref.watch(serverRepositoryProvider);
  return GetPostEngagementsUseCase(repository);
});

/// Get post engagement use case provider
final getPostEngagementUseCaseProvider =
    Provider<GetPostEngagementUseCase>((ref) {
  final repository = ref.watch(serverRepositoryProvider);
  return GetPostEngagementUseCase(repository);
});

/// Get post engagement by local ID use case provider
final getPostEngagementByLocalIdUseCaseProvider =
    Provider<GetPostEngagementByLocalIdUseCase>((ref) {
  final repository = ref.watch(serverRepositoryProvider);
  return GetPostEngagementByLocalIdUseCase(repository);
});

/// Refresh post engagement use case provider
final refreshPostEngagementUseCaseProvider =
    Provider<RefreshPostEngagementUseCase>((ref) {
  final repository = ref.watch(serverRepositoryProvider);
  return RefreshPostEngagementUseCase(repository);
});

/// Refresh post engagement by local ID use case provider
final refreshPostEngagementByLocalIdUseCaseProvider =
    Provider<RefreshPostEngagementByLocalIdUseCase>((ref) {
  final repository = ref.watch(serverRepositoryProvider);
  return RefreshPostEngagementByLocalIdUseCase(repository);
});

/// Refresh all engagements use case provider
final refreshAllEngagementsUseCaseProvider =
    Provider<RefreshAllEngagementsUseCase>((ref) {
  final repository = ref.watch(serverRepositoryProvider);
  return RefreshAllEngagementsUseCase(repository);
});

/// Delete server post use case provider
final deleteServerPostUseCaseProvider =
    Provider<DeleteServerPostUseCase>((ref) {
  final repository = ref.watch(serverRepositoryProvider);
  return DeleteServerPostUseCase(repository);
});

/// Provider for getting a server post by local ID
final getServerPostByLocalIdUseCaseProvider =
    Provider<GetServerPostByLocalIdUseCase>((ref) {
  final repository = ref.watch(serverRepositoryProvider);
  return GetServerPostByLocalIdUseCase(repository);
});

/// Refresh batch engagements use case provider
final refreshBatchEngagementsUseCaseProvider =
    Provider<RefreshBatchEngagementsUseCase>((ref) {
  final repository = ref.watch(serverRepositoryProvider);
  return RefreshBatchEngagementsUseCase(repository);
});
