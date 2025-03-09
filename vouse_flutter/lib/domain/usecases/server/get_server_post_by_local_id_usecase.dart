// lib/domain/usecases/server/get_server_post_by_local_id_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';
import 'package:vouse_flutter/domain/repository/server/server_repository.dart';

/// Parameters for getting a server post by local ID
class GetServerPostByLocalIdParams {
  final String postIdLocal;

  GetServerPostByLocalIdParams(this.postIdLocal);
}

/// A use case that retrieves a post from the server by its local ID.
class GetServerPostByLocalIdUseCase extends UseCase<DataState<PostEntity?>, GetServerPostByLocalIdParams> {
  final ServerRepository _repository;

  GetServerPostByLocalIdUseCase(this._repository);

  @override
  Future<DataState<PostEntity?>> call({GetServerPostByLocalIdParams? params}) {
    if (params == null) {
      throw ArgumentError('GetServerPostByLocalIdParams cannot be null');
    }
    return _repository.getServerPostByLocalId(params.postIdLocal);
  }
}