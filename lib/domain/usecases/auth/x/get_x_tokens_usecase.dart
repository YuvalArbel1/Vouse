import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/entities/x_auth_tokens.dart';
import 'package:vouse_flutter/domain/repository/auth/x_token_local_repository.dart';

class GetXTokensUseCase extends UseCase<DataState<XAuthTokens?>, void> {
  final XTokenLocalRepository _repo;

  GetXTokensUseCase(this._repo);

  @override
  Future<DataState<XAuthTokens?>> call({void params}) async {
    return _repo.getTokens();
  }
}
