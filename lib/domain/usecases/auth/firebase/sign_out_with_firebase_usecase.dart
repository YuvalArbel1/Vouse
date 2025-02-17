import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/auth/firebase_auth_repository.dart';

/// A use case that handles signing out the currently logged-in user
/// from Firebase. Returns a [DataState<void>] to indicate success/failure.
///
/// Usage:
///   final signOutUseCase = SignOutWithFirebaseUseCase(repo);
///   final result = await signOutUseCase.call(params: null);
class SignOutWithFirebaseUseCase implements UseCase<DataState<void>, void> {
  final FirebaseAuthRepository _repository;

  SignOutWithFirebaseUseCase(this._repository);

  /// Signs out the current user via [FirebaseAuthRepository].
  /// [params] is unused, so we accept null.
  @override
  Future<DataState<void>> call({void params}) {
    return _repository.signOut();
  }
}
