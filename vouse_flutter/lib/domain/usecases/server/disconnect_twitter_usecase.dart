// lib/domain/usecases/server/disconnect_twitter_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/server/server_repository.dart';

/// Parameters for disconnecting a Twitter account
class DisconnectTwitterParams {
  final String userId;

  DisconnectTwitterParams(this.userId);
}

/// A use case that disconnects a Twitter account from the server.
class DisconnectTwitterUseCase extends UseCase<DataState<void>, DisconnectTwitterParams> {
  final ServerRepository _repository;

  DisconnectTwitterUseCase(this._repository);

  @override
  Future<DataState<void>> call({DisconnectTwitterParams? params}) {
    if (params == null) {
      throw ArgumentError('DisconnectTwitterParams cannot be null');
    }
    return _repository.disconnectTwitter(params.userId);
  }
}