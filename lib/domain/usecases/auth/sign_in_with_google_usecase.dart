import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/auth/firebase_auth_repository.dart';

/// A use case to handle "sign in with Google" using FirebaseAuthRepository.
class SignInWithGoogleUseCase extends UseCase<DataState<void>, void> {
  final FirebaseAuthRepository _repository;

  SignInWithGoogleUseCase(this._repository);

  /// No params needed here
  @override
  Future<DataState<void>> call({void params}) {
    return _repository.signInWithGoogle();
  }
}
