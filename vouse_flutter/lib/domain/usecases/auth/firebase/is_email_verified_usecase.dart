// lib/domain/usecases/auth/firebase/is_email_verified_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/auth/firebase_auth_repository.dart';

/// Checks whether the currently signed-in user's email is verified.
///
/// The repository returns:
/// - [DataSuccess(true)] if verified,
/// - [DataSuccess(false)] if not verified,
/// - [DataFailed] on error.
class IsEmailVerifiedUseCase extends UseCase<DataState<bool>, void> {
  final FirebaseAuthRepository _repo;

  /// Requires a [FirebaseAuthRepository] to query the user's verification status.
  IsEmailVerifiedUseCase(this._repo);

  @override
  Future<DataState<bool>> call({void params}) {
    return _repo.isEmailVerified();
  }
}
