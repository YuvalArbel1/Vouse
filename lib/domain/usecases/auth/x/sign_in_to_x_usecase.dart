import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/auth/x_auth_repository.dart';

import '../../../entities/secure_db/x_auth_tokens.dart';

class SignInToXUseCase extends UseCase<DataState<XAuthTokens>, void> {
  final XAuthRepository _repo;

  SignInToXUseCase(this._repo);

  @override
  Future<DataState<XAuthTokens>> call({void params}) {
    return _repo.signInToX();
  }
}
