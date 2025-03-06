// lib/domain/usecases/auth/firebase/sign_out_with_firebase_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/auth/firebase_auth_repository.dart';

/// A use case that signs out the currently logged-in user from Firebase.
///
/// Returns a [DataSuccess<void>] if successful, or a [DataFailed<void>] on error.
class SignOutWithFirebaseUseCase implements UseCase<DataState<void>, void> {
  final FirebaseAuthRepository _repository;

  /// Requires a [FirebaseAuthRepository] to handle sign-out logic.
  SignOutWithFirebaseUseCase(this._repository);

  @override
  Future<DataState<void>> call({void params}) {
    return _repository.signOut();
  }
}
