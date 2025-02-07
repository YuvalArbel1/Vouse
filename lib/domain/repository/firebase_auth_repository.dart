import 'package:vouse_flutter/core/resources/data_state.dart';

abstract class FirebaseAuthRepository {
  Future<DataState<void>> signIn(String email, String password);

  Future<DataState<void>> signUp(String email, String password);

  // Future<DataState<void>> signOut();
}