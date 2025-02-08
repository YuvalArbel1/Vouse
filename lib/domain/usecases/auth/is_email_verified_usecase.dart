import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/auth/firebase_auth_repository.dart';

/// A use case that checks if the current user's email is verified.
///
/// The repository method returns [DataState<bool>]:
/// - [DataSuccess(true)] if verified,
/// - [DataSuccess(false)] if not verified,
/// - [DataFailed] on error.
class IsEmailVerifiedUseCase extends UseCase<DataState<bool>, void> {
  final FirebaseAuthRepository _repo;

  IsEmailVerifiedUseCase(this._repo);

  @override
  Future<DataState<bool>> call({void params}) {
    return _repo.isEmailVerified();
  }
}
