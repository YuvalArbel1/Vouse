// domain/usecases/posts/save_post_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';

import '../../entities/locaal db/post_entity.dart';
import '../../repository/local_db/post_local_repository.dart';

/// Params to provide the post + userId
class SavePostParams {
  final PostEntity post;
  final String userId;

  SavePostParams(this.post, this.userId);
}

class SavePostUseCase extends UseCase<DataState<void>, SavePostParams> {
  final PostLocalRepository _repo;

  SavePostUseCase(this._repo);

  @override
  Future<DataState<void>> call({SavePostParams? params}) {
    return _repo.savePost(params!.post, params.userId);
  }
}
