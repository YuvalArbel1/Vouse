import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/repository/auth/firebase_auth_repository.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';

// Simple params object to pass email & password
class SignInWithFirebaseParams {
  final String email;
  final String password;

  const SignInWithFirebaseParams({required this.email, required this.password});
}

class SignInWithFirebaseUseCase
    extends UseCase<DataState<void>, SignInWithFirebaseParams> {
  final FirebaseAuthRepository _repo;

  SignInWithFirebaseUseCase(this._repo);

  @override
  Future<DataState<void>> call({SignInWithFirebaseParams? params}) {
    return _repo.signIn(params!.email, params.password);
  }
}
