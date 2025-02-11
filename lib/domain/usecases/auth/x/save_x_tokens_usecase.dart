import 'package:dio/dio.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/entities/x_auth_tokens.dart';
import 'package:vouse_flutter/domain/repository/auth/x_token_local_repository.dart';

class SaveXTokensUseCase extends UseCase<DataState<void>, XAuthTokens> {
  final XTokenLocalRepository _repo;

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
