import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/auth/firebase_auth_repository.dart';

/// A use case to send a fresh verification email to the currently signed-in user.
/// If they are not signed in, the repository typically won't send anything.
class SendEmailVerificationUseCase extends UseCase<DataState<void>, void> {
  final FirebaseAuthRepository _repo;

  SendEmailVerificationUseCase(this._repo);

  @override
  Future<DataState<void>> call({void params}) {
    return _repo.sendEmailVerification();
  }
}
