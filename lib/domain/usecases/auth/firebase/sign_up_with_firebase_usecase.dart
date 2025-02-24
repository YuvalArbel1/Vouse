// lib/domain/usecases/auth/firebase/sign_up_with_firebase_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/auth/firebase_auth_repository.dart';

/// Holds [email] and [password] for Firebase sign-up.
class SignUpWithFirebaseParams {
  final String email;
  final String password;

  SignUpWithFirebaseParams({required this.email, required this.password});
}

/// A use case for registering a new user with Firebase.
///
/// After successful sign-up, the repository sends a verification email.
class SignUpWithFirebaseUseCase
    extends UseCase<DataState<void>, SignUpWithFirebaseParams> {
  final FirebaseAuthRepository _repo;

  SignUpWithFirebaseUseCase(this._repo);

  @override
  Future<DataState<void>> call({SignUpWithFirebaseParams? params}) {
    return _repo.signUp(params!.email, params.password);
  }
}
