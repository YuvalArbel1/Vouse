// lib/domain/usecases/auth/x/get_x_tokens_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/entities/secure_db/x_auth_tokens.dart';
import 'package:vouse_flutter/domain/repository/auth/x_token_local_repository.dart';

/// Retrieves stored X (Twitter) access & refresh tokens from secure storage.
class GetXTokensUseCase extends UseCase<DataState<XAuthTokens?>, void> {
  final XTokenLocalRepository _repo;

  /// Requires an [XTokenLocalRepository] that handles secure token retrieval.
  GetXTokensUseCase(this._repo);

  @override
  Future<DataState<XAuthTokens?>> call({void params}) async {
    return _repo.getTokens();
  }
}
