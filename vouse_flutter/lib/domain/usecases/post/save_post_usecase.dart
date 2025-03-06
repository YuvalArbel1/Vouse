// lib/domain/usecases/posts/save_post_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import '../../entities/local_db/post_entity.dart';
import '../../repository/local_db/post_local_repository.dart';

/// Holds the [post] to be saved and the corresponding [userId].
class SavePostParams {
  final PostEntity post;
  final String userId;

  /// Combines a [PostEntity] with the [userId] for foreign key reference.
  SavePostParams(this.post, this.userId);
}

/// A use case that inserts or updates a post in local storage.
class SavePostUseCase extends UseCase<DataState<void>, SavePostParams> {
  final PostLocalRepository _repo;

  /// Requires a [PostLocalRepository] to handle the insert/update logic.
  SavePostUseCase(this._repo);

  @override
  Future<DataState<void>> call({SavePostParams? params}) {
    return _repo.savePost(params!.post, params.userId);
  }
}
