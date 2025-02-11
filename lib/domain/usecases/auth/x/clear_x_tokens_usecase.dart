import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/auth/x_token_local_repository.dart';

class ClearXTokensUseCase extends UseCase<DataState<void>, void> {
  final XTokenLocalRepository _repo;

  ClearXTokensUseCase(this._repo);

  @override
  Future<DataState<void>> call({void params}) {
    return _repo.clearTokens();
  }
}
