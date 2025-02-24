// lib/domain/usecases/auth/firebase/forgot_password_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/auth/firebase_auth_repository.dart';

/// Parameters required by [ForgotPasswordUseCase].
class ForgotPasswordParams {
  final String email;

  /// Constructs params for a password reset request using [email].
  ForgotPasswordParams({required this.email});
}

/// Handles sending a password reset email to [ForgotPasswordParams.email] via FirebaseAuth.
class ForgotPasswordUseCase
    extends UseCase<DataState<void>, ForgotPasswordParams> {
  final FirebaseAuthRepository _repo;

  /// Expects a [FirebaseAuthRepository] to perform the actual reset operation.
  ForgotPasswordUseCase(this._repo);

  @override
  Future<DataState<void>> call({ForgotPasswordParams? params}) {
    return _repo.forgotPassword(params!.email);
  }
}
