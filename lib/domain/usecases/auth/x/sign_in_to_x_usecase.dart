// lib/domain/usecases/auth/x/sign_in_to_x_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/auth/x_auth_repository.dart';
import '../../../entities/secure_db/x_auth_tokens.dart';

/// A use case that initiates sign-in with X (Twitter) using [XAuthRepository].
class SignInToXUseCase extends UseCase<DataState<XAuthTokens>, void> {
  final XAuthRepository _repo;

  /// Requires an [XAuthRepository] to handle the OAuth flow.
  SignInToXUseCase(this._repo);

  @override
  Future<DataState<XAuthTokens>> call({void params}) {
    return _repo.signInToX();
  }
}
