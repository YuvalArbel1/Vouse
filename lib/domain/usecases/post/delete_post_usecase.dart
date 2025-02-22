// domain/usecases/posts/delete_post_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';

import '../../repository/local_db/post_local_repository.dart';

class DeletePostParams {
  final String postIdLocal;
  DeletePostParams(this.postIdLocal);
}

class DeletePostUseCase extends UseCase<DataState<void>, DeletePostParams> {
  final PostLocalRepository _repo;

  DeletePostUseCase(this._repo);

  @override
  Future<DataState<void>> call({DeletePostParams? params}) {
    return _repo.deletePost(params!.postIdLocal);
  }
}
