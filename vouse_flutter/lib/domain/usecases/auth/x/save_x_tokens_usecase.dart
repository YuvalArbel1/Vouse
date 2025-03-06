// lib/domain/usecases/auth/x/save_x_tokens_usecase.dart

import 'package:dio/dio.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/entities/secure_db/x_auth_tokens.dart';
import 'package:vouse_flutter/domain/repository/auth/x_token_local_repository.dart';

/// Saves X (Twitter) access & refresh tokens to secure storage.
///
/// If the provided [XAuthTokens] is null, returns [DataFailed].
class SaveXTokensUseCase extends UseCase<DataState<void>, XAuthTokens> {
  final XTokenLocalRepository _repo;

  /// Requires an [XTokenLocalRepository] to handle token storage.
  SaveXTokensUseCase(this._repo);

  @override
  Future<DataState<void>> call({XAuthTokens? params}) async {
    if (params == null) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: 'XAuthTokens was null',
        ),
      );
    }
    return _repo.saveTokens(params);
  }
}
