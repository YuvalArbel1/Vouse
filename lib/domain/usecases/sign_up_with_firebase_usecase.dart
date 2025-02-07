import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/repository/firebase_auth_repository.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';

// Simple params object to pass email & password
class SignUpWithFirebaseParams {
  final String email;
  final String password;

  SignUpWithFirebaseParams({required this.email, required this.password});
}

class SignUpWithFirebaseUseCase
    extends UseCase<DataState<void>, SignUpWithFirebaseParams> {
  final FirebaseAuthRepository _repo;

  SignUpWithFirebaseUseCase(this._repo);

  @override
  Future<DataState<void>> call({SignUpWithFirebaseParams? params}) {
    return _repo.signUp(params!.email, params.password);
  }
}
