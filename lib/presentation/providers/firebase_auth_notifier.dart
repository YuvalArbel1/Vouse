// lib/presentation/providers/firebase_auth_notifier.dart

import 'package:riverpod/riverpod.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/usecases/sign_in_with_firebase_usecase.dart';
import 'package:vouse_flutter/domain/usecases/sign_up_with_firebase_usecase.dart';

import 'firebase_auth_providers.dart';

// This provider exposes the state of sign-in / sign-up as DataState<void>
final firebaseAuthNotifierProvider =
StateNotifierProvider<FirebaseAuthNotifier, DataState<void>>((ref) {
  final signInUC = ref.watch(signInWithFirebaseUseCaseProvider);
  final signUpUC = ref.watch(signUpWithFirebaseUseCaseProvider);
  return FirebaseAuthNotifier(signInUC, signUpUC);
});

class FirebaseAuthNotifier extends StateNotifier<DataState<void>> {
  final SignInWithFirebaseUseCase _signInUseCase;
  final SignUpWithFirebaseUseCase _signUpUseCase;

  FirebaseAuthNotifier(this._signInUseCase, this._signUpUseCase)
      : super(DataSuccess(null));

  Future<void> signIn(String email, String password) async {
    state = DataSuccess(null); // or show loading
    final result = await _signInUseCase(
      params: SignInWithFirebaseParams(email: email, password: password),
    );
    state = result;
  }

  Future<void> signUp(String email, String password) async {
    state = DataSuccess(null); // or show loading
    final result = await _signUpUseCase(
      params: SignUpWithFirebaseParams(email: email, password: password),
    );
    state = result;
  }
}
