
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/auth/firebase_auth_repository.dart';

/// Params for calling [ForgotPasswordUseCase]
class ForgotPasswordParams {
  final String email;

  ForgotPasswordParams({required this.email});
}

/// A UseCase to handle "forgot password" (password reset) logic with Firebase.
class ForgotPasswordUseCase extends UseCase<DataState<void>, ForgotPasswordParams> {
  final FirebaseAuthRepository _repo;

  ForgotPasswordUseCase(this._repo);

  @override
  Future<DataState<void>> call({ForgotPasswordParams? params}) {
    return _repo.forgotPassword(params!.email);
  }
}
