// lib/domain/usecases/server/verify_twitter_tokens_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/server/server_repository.dart';

/// Parameters for verifying Twitter tokens
class VerifyTwitterTokensParams {
  final String userId;

  VerifyTwitterTokensParams(this.userId);
}

/// A use case that verifies if the stored Twitter tokens are valid.
///
/// Returns the username if tokens are valid, null if not.
class VerifyTwitterTokensUseCase
    extends UseCase<DataState<String?>, VerifyTwitterTokensParams> {
  final ServerRepository _repository;

  VerifyTwitterTokensUseCase(this._repository);

  @override
  Future<DataState<String?>> call({VerifyTwitterTokensParams? params}) {
    if (params == null) {
      throw ArgumentError('VerifyTwitterTokensParams cannot be null');
    }
    return _repository.verifyTwitterTokens(params.userId);
  }
}