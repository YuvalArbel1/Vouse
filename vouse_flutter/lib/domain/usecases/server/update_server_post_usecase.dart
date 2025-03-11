// lib/domain/usecases/server/update_server_post_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/domain/repository/server/server_repository.dart';

/// Parameters for updating a post on the server
class UpdateServerPostParams {
  final String id;
  final PostEntity post;

  UpdateServerPostParams(this.id, this.post);
}

/// A use case that updates a post on the server.
class UpdateServerPostUseCase extends UseCase<DataState<PostEntity>, UpdateServerPostParams> {
  final ServerRepository _repository;

  UpdateServerPostUseCase(this._repository);

  @override
  Future<DataState<PostEntity>> call({UpdateServerPostParams? params}) {
    if (params == null) {
      throw ArgumentError('UpdateServerPostParams cannot be null');
    }
    return _repository.updateServerPost(params.id, params.post);
  }
}