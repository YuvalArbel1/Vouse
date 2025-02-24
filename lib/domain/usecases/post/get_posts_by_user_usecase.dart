// lib/domain/usecases/posts/get_posts_by_user_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import '../../entities/local_db/post_entity.dart';
import '../../repository/local_db/post_local_repository.dart';

/// Contains a [userId] needed to fetch all posts belonging to that user.
class GetPostsByUserParams {
  final String userId;

  /// Creates params for retrieving posts by [userId].
  GetPostsByUserParams(this.userId);
}

/// Retrieves all [PostEntity] records associated with [userId].
///
/// Returns a [DataState] with a list of posts or an error.
class GetPostsByUserUseCase
    extends UseCase<DataState<List<PostEntity>>, GetPostsByUserParams> {
  final PostLocalRepository _repo;

  /// Requires a [PostLocalRepository] to access local post data.
  GetPostsByUserUseCase(this._repo);

  @override
  Future<DataState<List<PostEntity>>> call({GetPostsByUserParams? params}) {
    return _repo.getPostsByUser(params!.userId);
  }
}
