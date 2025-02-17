import 'package:riverpod/riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vouse_flutter/data/repository/auth/firebase_auth_repository_impl.dart';
import 'package:vouse_flutter/domain/repository/auth/firebase_auth_repository.dart';
import 'package:vouse_flutter/domain/usecases/auth/firebase/sign_in_with_firebase_usecase.dart';
import 'package:vouse_flutter/domain/usecases/auth/firebase/sign_up_with_firebase_usecase.dart';
import 'package:vouse_flutter/domain/usecases/auth/firebase/forgot_password_usecase.dart';
import 'package:vouse_flutter/domain/usecases/auth/firebase/send_email_verification_usecase.dart';
import 'package:vouse_flutter/domain/usecases/auth/firebase/is_email_verified_usecase.dart';
import 'package:vouse_flutter/domain/usecases/auth/firebase/sign_in_with_google_usecase.dart';

// NEW: Import the signOut use case
import 'package:vouse_flutter/domain/usecases/auth/firebase/sign_out_with_firebase_usecase.dart';

/// Provides a singleton instance of [FirebaseAuthRepository],
/// which uses [FirebaseAuthRepositoryImpl].
final firebaseAuthRepositoryProvider = Provider<FirebaseAuthRepository>((ref) {
  return FirebaseAuthRepositoryImpl(FirebaseAuth.instance);
});

// Provide the signIn use case
final signInWithFirebaseUseCaseProvider = Provider<SignInWithFirebaseUseCase>((ref) {
  final repo = ref.watch(firebaseAuthRepositoryProvider);
  return SignInWithFirebaseUseCase(repo);
});

// Provide the signUp use case
final signUpWithFirebaseUseCaseProvider = Provider<SignUpWithFirebaseUseCase>((ref) {
  final repo = ref.watch(firebaseAuthRepositoryProvider);
  return SignUpWithFirebaseUseCase(repo);
});

// Provide the forgotPassword use case
final forgotPasswordUseCaseProvider = Provider<ForgotPasswordUseCase>((ref) {
  final repo = ref.watch(firebaseAuthRepositoryProvider);
  return ForgotPasswordUseCase(repo);
});

// Provide the sendEmailVerification use case
final sendEmailVerificationUseCaseProvider = Provider<SendEmailVerificationUseCase>((ref) {
  final repo = ref.watch(firebaseAuthRepositoryProvider);
  return SendEmailVerificationUseCase(repo);
});

// Provide the isEmailVerified use case
final isEmailVerifiedUseCaseProvider = Provider<IsEmailVerifiedUseCase>((ref) {
  final repo = ref.watch(firebaseAuthRepositoryProvider);
  return IsEmailVerifiedUseCase(repo);
});

/// Provide signInWithGoogleUseCase
final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogleUseCase>((ref) {
  final repo = ref.watch(firebaseAuthRepositoryProvider);
  return SignInWithGoogleUseCase(repo);
});

/// A provider that creates a [SignOutWithFirebaseUseCase]
/// by injecting the [firebaseAuthRepositoryProvider].
final signOutWithFirebaseUseCaseProvider = Provider<SignOutWithFirebaseUseCase>((ref) {
  final repo = ref.watch(firebaseAuthRepositoryProvider);
  return SignOutWithFirebaseUseCase(repo);
});
