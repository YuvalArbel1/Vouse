// lib/presentation/providers/home/home_posts_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';

import '../../../domain/usecases/post/get_posts_by_user_usecase.dart';
import '../local_db/local_post_providers.dart';
import '../post/post_refresh_provider.dart';

/// Returns all "draft" posts for the current user.
/// A "draft" post is one with [scheduledAt] == null && [updatedAt] == null.
final draftPostsProvider =
    FutureProvider.autoDispose<List<PostEntity>>((ref) async {
  // Watch the refresh trigger so this provider refreshes when triggered
  ref.watch(draftRefreshProvider);

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  final getPostsUseCase = ref.watch(getPostsByUserUseCaseProvider);
  final result =
      await getPostsUseCase.call(params: GetPostsByUserParams(user.uid));

  if (result is DataSuccess<List<PostEntity>>) {
    // New definition: A draft has no scheduled date and no postIdX (not posted)
    return result.data!
        .where((post) => post.scheduledAt == null && post.postIdX == null)
        .toList();
  }

  return [];
});

/// Returns all "scheduled" posts for the current user.
/// A "scheduled" post is one with [scheduledAt] != null.
final scheduledPostsProvider =
    FutureProvider.autoDispose<List<PostEntity>>((ref) async {
  // Watch the refresh trigger so this provider refreshes when triggered
  ref.watch(scheduledRefreshProvider);

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  final getPostsUseCase = ref.watch(getPostsByUserUseCaseProvider);
  final result =
      await getPostsUseCase.call(params: GetPostsByUserParams(user.uid));

  if (result is DataSuccess<List<PostEntity>>) {
    return result.data!.where((post) => post.scheduledAt != null).toList();
  }

  return [];
});

/// Returns all "posted" posts for the current user.
/// A "posted" post is one with [updatedAt] != null.
final postedPostsProvider =
    FutureProvider.autoDispose<List<PostEntity>>((ref) async {
  // Watch the refresh trigger so this provider refreshes when triggered
  ref.watch(postedRefreshProvider);

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  final getPostsUseCase = ref.watch(getPostsByUserUseCaseProvider);
  final result =
      await getPostsUseCase.call(params: GetPostsByUserParams(user.uid));

  if (result is DataSuccess<List<PostEntity>>) {
    // A post is "posted" if it has updatedAt AND doesn't have scheduledAt
    return result.data!.where((post) => post.postIdX != null).toList();
  }

  return [];
});
