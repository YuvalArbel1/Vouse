// lib/domain/usecases/server/connect_twitter_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/entities/secure_db/x_auth_tokens.dart';
import 'package:vouse_flutter/domain/repository/server/server_repository.dart';

/// Parameters for connecting a Twitter account
class ConnectTwitterParams {
  final String userId;
  final XAuthTokens tokens;

  ConnectTwitterParams({
    required this.userId,
    required this.tokens,
  });
}

/// A use case that sends Twitter OAuth tokens to the server to connect an account.
class ConnectTwitterUseCase extends UseCase<DataState<void>, ConnectTwitterParams> {
  final ServerRepository _repository;

  ConnectTwitterUseCase(this._repository);

  @override
  Future<DataState<void>> call({ConnectTwitterParams? params}) {
    if (params == null) {
      throw ArgumentError('ConnectTwitterParams cannot be null');
    }
    return _repository.connectTwitter(params.userId, params.tokens);
  }
}