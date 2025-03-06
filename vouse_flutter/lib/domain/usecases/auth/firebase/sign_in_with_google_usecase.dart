// lib/domain/usecases/auth/firebase/sign_in_with_google_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/auth/firebase_auth_repository.dart';

/// A use case that initiates Google sign-in via [FirebaseAuthRepository].
class SignInWithGoogleUseCase extends UseCase<DataState<void>, void> {
  final FirebaseAuthRepository _repository;

  /// Does not require parameters; the repository handles the flow.
  SignInWithGoogleUseCase(this._repository);

  @override
  Future<DataState<void>> call({void params}) {
    return _repository.signInWithGoogle();
  }
}
