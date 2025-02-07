
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/data/repository/firebase_auth_repository_impl.dart';
import 'package:vouse_flutter/domain/repository/firebase_auth_repository.dart';
import 'package:vouse_flutter/domain/usecases/sign_in_with_firebase_usecase.dart';
import 'package:vouse_flutter/domain/usecases/sign_up_with_firebase_usecase.dart';

// 1. Provide an instance of FirebaseAuthRepository
final firebaseAuthRepositoryProvider = Provider<FirebaseAuthRepository>((ref) {
  return FirebaseAuthRepositoryImpl(FirebaseAuth.instance);
});

// 2. Provide SignInWithFirebaseUseCase
final signInWithFirebaseUseCaseProvider =
Provider<SignInWithFirebaseUseCase>((ref) {
  final repo = ref.watch(firebaseAuthRepositoryProvider);
  return SignInWithFirebaseUseCase(repo);
});

// 3. Provide SignUpWithFirebaseUseCase
final signUpWithFirebaseUseCaseProvider =
Provider<SignUpWithFirebaseUseCase>((ref) {
  final repo = ref.watch(firebaseAuthRepositoryProvider);
  return SignUpWithFirebaseUseCase(repo);
});
