// lib/domain/usecases/server/check_twitter_status_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/server/server_repository.dart';

/// Parameters for checking Twitter connection status
class CheckTwitterStatusParams {
  final String userId;

  CheckTwitterStatusParams(this.userId);
}

/// A use case that checks if a Twitter account is connected on the server.
class CheckTwitterStatusUseCase extends UseCase<DataState<bool>, CheckTwitterStatusParams> {
  final ServerRepository _repository;

  CheckTwitterStatusUseCase(this._repository);

  @override
  Future<DataState<bool>> call({CheckTwitterStatusParams? params}) {
    if (params == null) {
      throw ArgumentError('CheckTwitterStatusParams cannot be null');
    }
    return _repository.isTwitterConnected(params.userId);
  }
}