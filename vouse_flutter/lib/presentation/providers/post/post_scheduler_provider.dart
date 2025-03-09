// lib/presentation/providers/post/post_scheduler_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/domain/usecases/post/save_post_usecase.dart';
import 'package:vouse_flutter/domain/usecases/server/schedule_post_usecase.dart';
import 'package:vouse_flutter/presentation/providers/post/post_refresh_provider.dart';
import 'package:vouse_flutter/presentation/providers/local_db/local_post_providers.dart';
import 'package:vouse_flutter/presentation/providers/home/home_content_provider.dart';

import '../server/server_providers.dart';

/// State of the post scheduling process
enum SchedulingState {
  initial,
  scheduling,
  scheduled,
  failed,
  localOnly
}

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
  Future<bool> schedulePost({
    required PostEntity post,
    required String userId,
    bool saveLocally = true,
  }) async {
    try {
      state = state.copyWith(state: SchedulingState.scheduling);

      // Always save locally first to ensure we don't lose the post
      if (saveLocally) {
        await _savePostUseCase.call(
          params: SavePostParams(post, userId),
        );
      }

      // Then, send to server
      final serverResult = await _schedulePostUseCase.call(
        params: SchedulePostParams(post),
      );

      if (serverResult is DataSuccess<String>) {
        // Update state with success
        state = state.copyWith(
          state: SchedulingState.scheduled,
          serverId: serverResult.data,
        );

        // Refresh relevant providers
        _ref.read(postRefreshProvider.notifier).refreshAll();
        _ref.read(homeContentProvider.notifier).refreshHomeContent();

        return true;
      } else if (serverResult is DataFailed) {
        // If server scheduling failed but we saved locally
        if (saveLocally) {
          state = state.copyWith(
            state: SchedulingState.localOnly,
            errorMessage: serverResult.error?.error.toString() ?? 'Failed to schedule on server',
          );
          // Still refresh local content providers
          _ref.read(postRefreshProvider.notifier).refreshAll();
          return true;
        } else {
          // Failed completely
          throw Exception(serverResult.error?.error.toString() ?? 'Failed to schedule post');
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