// lib/presentation/providers/post/home_posts_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';

import '../../../domain/usecases/post/get_posts_by_user_usecase.dart';
import '../local_db/local_post_providers.dart';

/// Returns all "draft" posts for the current user.
/// A "draft" post is one with [scheduledAt] == null && [updatedAt] == null.
final draftPostsProvider = FutureProvider<List<PostEntity>>((ref) async {
  // 1) Check if user is logged in
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];

  // 2) Obtain the use case
  final getPostsUseCase = ref.watch(getPostsByUserUseCaseProvider);

  // 3) Execute the use case
  final result =
      await getPostsUseCase.call(params: GetPostsByUserParams(user.uid));

  // 4) If successful, filter out only draft posts; otherwise return []
  if (result is DataSuccess<List<PostEntity>>) {
    return result.data!.where((post) => post.scheduledAt == null).toList();
  }

  return [];
});

/// Returns all "scheduled" posts for the current user.
/// A "scheduled" post is one with [scheduledAt] != null.
final scheduledPostsProvider = FutureProvider<List<PostEntity>>((ref) async {
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
