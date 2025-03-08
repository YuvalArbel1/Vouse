// lib/domain/usecases/server/get_server_posts_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/domain/repository/server/server_repository.dart';

/// A use case that retrieves all posts from the server.
class GetServerPostsUseCase extends UseCase<DataState<List<PostEntity>>, void> {
  final ServerRepository _repository;

  GetServerPostsUseCase(this._repository);

  @override
  Future<DataState<List<PostEntity>>> call({void params}) {
    return _repository.getServerPosts();
  }
}