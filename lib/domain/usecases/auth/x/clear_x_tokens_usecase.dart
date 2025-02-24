// lib/domain/usecases/auth/x/clear_x_tokens_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/auth/x_token_local_repository.dart';

/// A use case that clears stored X (Twitter) tokens from secure storage.
class ClearXTokensUseCase extends UseCase<DataState<void>, void> {
  final XTokenLocalRepository _repo;

  /// Requires an [XTokenLocalRepository] to handle the removal of tokens.
  ClearXTokensUseCase(this._repo);

  @override
  Future<DataState<void>> call({void params}) {
    return _repo.clearTokens();
  }
}
