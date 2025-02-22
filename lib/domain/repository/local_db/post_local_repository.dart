import 'package:vouse_flutter/core/resources/data_state.dart';

import '../../entities/locaal db/post_entity.dart';

abstract class PostLocalRepository {
  /// Save (insert or update) a post. Needs the userId for the foreign key.
  Future<DataState<void>> savePost(PostEntity post, String userId);

  /// Get all posts for a specific user
  Future<DataState<List<PostEntity>>> getPostsByUser(String userId);

  /// Get a single post by postIdLocal
  Future<DataState<PostEntity?>> getPostById(String postIdLocal);

  /// Delete a post
  Future<DataState<void>> deletePost(String postIdLocal);
}
