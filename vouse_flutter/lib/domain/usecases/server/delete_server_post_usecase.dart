// lib/domain/usecases/server/delete_server_post_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/server/server_repository.dart';

/// Parameters for deleting a post from the server
class DeleteServerPostParams {
  final String id;

  DeleteServerPostParams(this.id);
}

/// A use case that deletes a post from the server.
class DeleteServerPostUseCase extends UseCase<DataState<void>, DeleteServerPostParams> {
  final ServerRepository _repository;

  DeleteServerPostUseCase(this._repository);

  @override
  Future<DataState<void>> call({DeleteServerPostParams? params}) {
    if (params == null) {
      throw ArgumentError('DeleteServerPostParams cannot be null');
    }
    return _repository.deleteServerPost(params.id);
  }
}