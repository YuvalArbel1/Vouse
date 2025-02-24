// lib/domain/repository/local_db/post_local_repository.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import '../../entities/local_db/post_entity.dart';

/// Defines local storage operations for post data.
abstract class PostLocalRepository {
  /// Inserts or updates [post], requiring a [userId] to maintain the foreign key relationship.
  Future<DataState<void>> savePost(PostEntity post, String userId);

  /// Retrieves all posts created by [userId].
  Future<DataState<List<PostEntity>>> getPostsByUser(String userId);

  /// Gets a single post by its [postIdLocal].
  Future<DataState<PostEntity?>> getPostById(String postIdLocal);

  /// Deletes a post by its [postIdLocal].
  Future<DataState<void>> deletePost(String postIdLocal);
}
