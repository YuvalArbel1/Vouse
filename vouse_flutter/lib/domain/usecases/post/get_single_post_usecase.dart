// lib/domain/usecases/posts/get_single_post_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import '../../entities/local_db/post_entity.dart';
import '../../repository/local_db/post_local_repository.dart';

/// Holds a [postIdLocal] for retrieving a specific post from local storage.
class GetSinglePostParams {
  final String postIdLocal;

  /// Requires the local post ID.
  GetSinglePostParams(this.postIdLocal);
}

/// Fetches a single [PostEntity] by [postIdLocal],
/// returning `null` if no matching post is found.
class GetSinglePostUseCase
    extends UseCase<DataState<PostEntity?>, GetSinglePostParams> {
  final PostLocalRepository _repo;

  /// Requires a [PostLocalRepository] to handle the database lookup.
  GetSinglePostUseCase(this._repo);

  @override
  Future<DataState<PostEntity?>> call({GetSinglePostParams? params}) {
    return _repo.getPostById(params!.postIdLocal);
  }
}
