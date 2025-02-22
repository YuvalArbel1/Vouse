// domain/usecases/posts/get_single_post_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';

import '../../entities/locaal db/post_entity.dart';
import '../../repository/local_db/post_local_repository.dart';

class GetSinglePostParams {
  final String postIdLocal;
  GetSinglePostParams(this.postIdLocal);
}

class GetSinglePostUseCase
    extends UseCase<DataState<PostEntity?>, GetSinglePostParams> {
  final PostLocalRepository _repo;

  GetSinglePostUseCase(this._repo);

  @override
  Future<DataState<PostEntity?>> call({GetSinglePostParams? params}) {
    return _repo.getPostById(params!.postIdLocal);
  }
}
