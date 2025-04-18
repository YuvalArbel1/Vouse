// lib/domain/usecases/auth/firebase/sign_in_with_firebase_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/auth/firebase_auth_repository.dart';

/// Holds the [email] and [password] used for Firebase sign-in.
class SignInWithFirebaseParams {
  final String email;
  final String password;

  const SignInWithFirebaseParams({required this.email, required this.password});
}

/// A use case for signing in an existing user via FirebaseAuth.
class SignInWithFirebaseUseCase
    extends UseCase<DataState<void>, SignInWithFirebaseParams> {
  final FirebaseAuthRepository _repo;

  /// Requires a [FirebaseAuthRepository] to handle the credential check.
  SignInWithFirebaseUseCase(this._repo);

  @override
  Future<DataState<void>> call({SignInWithFirebaseParams? params}) {
    return _repo.signIn(params!.email, params.password);
  }
}
