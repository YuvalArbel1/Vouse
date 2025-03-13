// lib/presentation/providers/post/post_scheduler_provider.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/domain/usecases/post/save_post_usecase.dart';
import 'package:vouse_flutter/domain/usecases/post/save_post_with_upload_usecase.dart';
import 'package:vouse_flutter/domain/usecases/post/get_single_post_usecase.dart';
import 'package:vouse_flutter/domain/usecases/server/schedule_post_usecase.dart';
import 'package:vouse_flutter/presentation/providers/post/post_refresh_provider.dart';
import 'package:vouse_flutter/presentation/providers/local_db/local_post_providers.dart';
import 'package:vouse_flutter/presentation/providers/home/home_content_provider.dart';
import 'package:vouse_flutter/presentation/providers/post/save_post_with_upload_provider.dart';

import '../../../domain/usecases/server/get_server_post_by_local_id_usecase.dart';
import '../../../domain/usecases/server/update_server_post_usecase.dart';
import '../home/home_posts_providers.dart';
import '../server/server_providers.dart';

/// State of the post scheduling process
enum SchedulingState { initial, scheduling, scheduled, failed, localOnly }

/// State for the post scheduler provider
class PostSchedulerState {
  final SchedulingState state;
  final String? errorMessage;
  final String? serverId;

  PostSchedulerState({
    this.state = SchedulingState.initial,
    this.errorMessage,
    this.serverId,
  });

  PostSchedulerState copyWith({
    SchedulingState? state,
    String? errorMessage,
    String? serverId,
  }) {
    return PostSchedulerState(
      state: state ?? this.state,
      errorMessage: errorMessage ?? this.errorMessage,
      serverId: serverId ?? this.serverId,
    );
  }
}

/// Notifier for handling post scheduling logic
class PostSchedulerNotifier extends StateNotifier<PostSchedulerState> {
  final SavePostUseCase _savePostUseCase;
  final SchedulePostUseCase _schedulePostUseCase;
  final Ref _ref;

  PostSchedulerNotifier({
    required SavePostUseCase savePostUseCase,
    required SchedulePostUseCase schedulePostUseCase,
    required Ref ref,
  })  : _savePostUseCase = savePostUseCase,
        _schedulePostUseCase = schedulePostUseCase,
        _ref = ref,
        super(PostSchedulerState());

  /// Schedule a post on the server and save it locally
  /// Update the PostSchedulerNotifier to add an isUpdating parameter
  Future<bool> schedulePost({
    required PostEntity post,
    required String userId,
    bool saveLocally = true,
    bool isUpdating = false,
  }) async {
    try {
      state = state.copyWith(state: SchedulingState.scheduling);

      // Create a mutable copy of the post's cloud URLs
      List<String> updatedCloudUrls = List.from(post.cloudImageUrls);

      // When updating, check if we need to delete old images
      if (isUpdating) {
        final getOriginalPostResult =
            await _ref.read(getSinglePostUseCaseProvider).call(
                  params: GetSinglePostParams(post.postIdLocal),
                );

        if (getOriginalPostResult is DataSuccess<PostEntity?> &&
            getOriginalPostResult.data != null) {
          final originalPost = getOriginalPostResult.data!;

          // Find URLs of images that should be deleted (not in the new post)
          final imagesToDelete = <String>[];
          for (final cloudUrl in originalPost.cloudImageUrls) {
            // If this URL is not in the new post's cloud URLs, mark for deletion
            if (!post.cloudImageUrls.contains(cloudUrl)) {
              imagesToDelete.add(cloudUrl);
            }
          }

          // Delete the old images from Firebase Storage
          if (imagesToDelete.isNotEmpty) {
            final imagesRepo = _ref.read(imagesRepositoryProvider);
            await imagesRepo.deleteImagesFromFirebase(imagesToDelete);

            // Remove deleted URLs from our updated list
            updatedCloudUrls = updatedCloudUrls
                .where((url) => !imagesToDelete.contains(url))
                .toList();
          }
        }
      }

      // Create a new post with the updated cloud URLs
      PostEntity updatedPost = post.copyWith(cloudImageUrls: updatedCloudUrls);

      // Check if there are local images that need uploading
      if (post.localImagePaths.isNotEmpty) {
        // Use the SavePostWithUploadUseCase to upload images first
        final saveWithUploadUseCase =
            _ref.read(savePostWithUploadUseCaseProvider);

        final params = SavePostWithUploadParams(
          userUid: userId,
          postEntity: updatedPost,
          localImageFiles:
              post.localImagePaths.map((path) => File(path)).toList(),
        );

        final result = await saveWithUploadUseCase.call(params: params);

        if (result is DataFailed) {
          throw Exception(
              result.error?.error.toString() ?? 'Failed to upload images');
        }

        // Fetch the updated post with cloud URLs from the local DB
        final getPostResult =
            await _ref.read(getSinglePostUseCaseProvider).call(
                  params: GetSinglePostParams(post.postIdLocal),
                );

        if (getPostResult is DataSuccess<PostEntity?> &&
            getPostResult.data != null) {
          updatedPost = getPostResult.data!;
        }
      } else if (saveLocally) {
        // No images to upload, just save locally
        await _savePostUseCase.call(
          params: SavePostParams(updatedPost, userId),
        );
      }

      // Then, send to server with updated post (containing cloud URLs)
      DataState<String> serverResult;

      if (isUpdating) {
        // Get the server ID of the post
        final serverPostResult =
            await _ref.read(getServerPostByLocalIdUseCaseProvider).call(
                  params: GetServerPostByLocalIdParams(post.postIdLocal),
                );

        if (serverPostResult is DataSuccess && serverPostResult.data != null) {
          // Update the post on the server
          final updateResult = await _ref
              .read(updateServerPostUseCaseProvider)
              .call(
                params: UpdateServerPostParams(
                  serverPostResult.data!.postIdLocal,
                  updatedPost,
                ),
              );

          if (updateResult is DataSuccess) {
            serverResult = DataSuccess<String>(updateResult.data!.postIdLocal);
          } else if (updateResult is DataFailed) {
            serverResult = DataFailed<String>(
              DioException(
                requestOptions: RequestOptions(path: ''),
                error: updateResult.error?.error ?? 'Failed to update post',
              ),
            );
          } else {
            throw Exception("Unexpected update result");
          }
        } else {
          // If not found on server, fallback to creating new
          serverResult = await _schedulePostUseCase.call(
            params: SchedulePostParams(updatedPost),
          );
        }
      } else {
        // Create new post
        serverResult = await _schedulePostUseCase.call(
          params: SchedulePostParams(updatedPost),
        );
      }

      if (serverResult is DataSuccess<String>) {
        // Update state with success
        state = state.copyWith(
          state: SchedulingState.scheduled,
          serverId: serverResult.data,
        );

        // Refresh relevant providers
        _ref.read(postRefreshProvider.notifier).refreshAll();

        // Explicitly refresh posted posts if this is an immediate post
        if (post.scheduledAt == null ||
            post.scheduledAt!.isBefore(DateTime.now())) {
          _ref.read(postRefreshProvider.notifier).refreshPosted();

          // Force invalidate the providers to ensure they reload data
          _ref.invalidate(postedPostsProvider);
        }

        // Force refresh home content with more aggressiveness
        _ref.invalidate(homeContentProvider);
        _ref.read(homeContentProvider.notifier).refreshHomeContent();

        return true;
      } else if (serverResult is DataFailed) {
        // If server scheduling failed but we saved locally
        if (saveLocally) {
          state = state.copyWith(
            state: SchedulingState.localOnly,
            errorMessage: serverResult.error?.error.toString() ??
                'Failed to schedule on server',
          );
          // Still refresh local content providers
          _ref.read(postRefreshProvider.notifier).refreshAll();
          return true;
        } else {
          // Failed completely
          throw Exception(serverResult.error?.error.toString() ??
              'Failed to schedule post');
        }
      }

      return false;
    } catch (e) {
      // Update state with error
      state = state.copyWith(
        state: SchedulingState.failed,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Reset the state to initial
  void reset() {
    state = PostSchedulerState();
  }
}

/// Provider for post scheduler
final postSchedulerProvider =
    StateNotifierProvider<PostSchedulerNotifier, PostSchedulerState>((ref) {
  return PostSchedulerNotifier(
    savePostUseCase: ref.watch(savePostUseCaseProvider),
    schedulePostUseCase: ref.watch(schedulePostUseCaseProvider),
    ref: ref,
  );
});
