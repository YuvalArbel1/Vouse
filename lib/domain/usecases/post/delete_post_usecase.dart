// lib/domain/usecases/posts/delete_post_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import '../../repository/local_db/post_local_repository.dart';

/// Parameters required to delete a specific post by [postIdLocal].
class DeletePostParams {
  final String postIdLocal;

  /// Requires the local ID of the post.
  DeletePostParams(this.postIdLocal);
}

/// A use case that removes a post from local storage.
class DeletePostUseCase extends UseCase<DataState<void>, DeletePostParams> {
  final PostLocalRepository _repo;

  /// Requires a [PostLocalRepository] to perform the deletion.
  DeletePostUseCase(this._repo);

  @override
  Future<DataState<void>> call({DeletePostParams? params}) {
    return _repo.deletePost(params!.postIdLocal);
  }
}
