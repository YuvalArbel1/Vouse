// lib/domain/usecases/auth/firebase/send_email_verification_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/auth/firebase_auth_repository.dart';

/// Sends a fresh verification email to the currently signed-in user.
/// If the user is not signed in, the repository typically does nothing.
class SendEmailVerificationUseCase extends UseCase<DataState<void>, void> {
  final FirebaseAuthRepository _repo;

  /// Requires a [FirebaseAuthRepository] to handle sending the email.
  SendEmailVerificationUseCase(this._repo);

  @override
  Future<DataState<void>> call({void params}) {
    return _repo.sendEmailVerification();
  }
}
