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
/// Returns all "draft" posts for the current user, sorted by updatedAt time (newest first).
/// A "draft" post is one with [scheduledAt] == null && [postIdX] == null.
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
    final drafts = result.data!
        .where((post) => post.scheduledAt == null && post.postIdX == null)
        .toList();

    // Sort drafts by updatedAt time, newest first
    // If updatedAt is null, fall back to createdAt
    drafts.sort((a, b) =>
        (b.updatedAt ?? b.createdAt).compareTo(a.updatedAt ?? a.createdAt));

    return drafts;
  }

  return [];
});

/// Returns all "scheduled" posts for the current user.
/// A "scheduled" post is one with [scheduledAt] != null AND [postIdX] == null.
/// This ensures posted posts don't appear in scheduled section.
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
    // Updated condition: scheduled AND not yet posted
    final scheduled = result.data!
        .where((post) => post.scheduledAt != null && post.postIdX == null)
        .toList();

    // Sort by scheduled time
    scheduled.sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));

    return scheduled;
  }

  return [];
});

/// Returns all "posted" posts for the current user.
/// A "posted" post is one with [postIdX] != null.
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
    // A post is "posted" if it has a postIdX
    final posted = result.data!.where((post) => post.postIdX != null).toList();

    // Sort by updated time, newest first
    posted.sort((a, b) =>
        (b.updatedAt ?? b.createdAt).compareTo(a.updatedAt ?? a.createdAt));

    return posted;
  }

  return [];
});
