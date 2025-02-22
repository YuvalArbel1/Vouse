// domain/usecases/posts/get_posts_by_user_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';

import '../../entities/locaal db/post_entity.dart';
import '../../repository/local_db/post_local_repository.dart';

class GetPostsByUserParams {
  final String userId;
  GetPostsByUserParams(this.userId);
}

class GetPostsByUserUseCase
    extends UseCase<DataState<List<PostEntity>>, GetPostsByUserParams> {
  final PostLocalRepository _repo;

  GetPostsByUserUseCase(this._repo);

  @override
  Future<DataState<List<PostEntity>>> call({GetPostsByUserParams? params}) {
    return _repo.getPostsByUser(params!.userId);
  }
}
