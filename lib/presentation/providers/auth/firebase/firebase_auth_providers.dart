// lib/presentation/providers/firebase/firebase_auth_providers.dart

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
import 'package:vouse_flutter/domain/usecases/auth/firebase/sign_out_with_firebase_usecase.dart';

/// Provides a singleton [FirebaseAuthRepository] using [FirebaseAuthRepositoryImpl],
/// which in turn wraps [FirebaseAuth.instance] for sign-in, sign-up, etc.
final firebaseAuthRepositoryProvider = Provider<FirebaseAuthRepository>((ref) {
  return FirebaseAuthRepositoryImpl(FirebaseAuth.instance);
});

/// Creates a [SignInWithFirebaseUseCase] that signs in a user with email/password.
final signInWithFirebaseUseCaseProvider =
    Provider<SignInWithFirebaseUseCase>((ref) {
  final repo = ref.watch(firebaseAuthRepositoryProvider);
  return SignInWithFirebaseUseCase(repo);
});

/// Creates a [SignUpWithFirebaseUseCase] to register a new user and send verification email.
final signUpWithFirebaseUseCaseProvider =
    Provider<SignUpWithFirebaseUseCase>((ref) {
  final repo = ref.watch(firebaseAuthRepositoryProvider);
  return SignUpWithFirebaseUseCase(repo);
});

/// Creates a [ForgotPasswordUseCase] for sending a password reset email.
final forgotPasswordUseCaseProvider = Provider<ForgotPasswordUseCase>((ref) {
  final repo = ref.watch(firebaseAuthRepositoryProvider);
  return ForgotPasswordUseCase(repo);
});

/// Creates a [SendEmailVerificationUseCase] to re-send a verification email.
final sendEmailVerificationUseCaseProvider =
    Provider<SendEmailVerificationUseCase>((ref) {
  final repo = ref.watch(firebaseAuthRepositoryProvider);
  return SendEmailVerificationUseCase(repo);
});

/// Creates an [IsEmailVerifiedUseCase] to check the current user's verification status.
final isEmailVerifiedUseCaseProvider = Provider<IsEmailVerifiedUseCase>((ref) {
  final repo = ref.watch(firebaseAuthRepositoryProvider);
  return IsEmailVerifiedUseCase(repo);
});

/// Creates a [SignInWithGoogleUseCase] to handle Google OAuth via FirebaseAuth.
final signInWithGoogleUseCaseProvider =
    Provider<SignInWithGoogleUseCase>((ref) {
  final repo = ref.watch(firebaseAuthRepositoryProvider);
  return SignInWithGoogleUseCase(repo);
});

/// Creates a [SignOutWithFirebaseUseCase] to sign out the current Firebase user.
final signOutWithFirebaseUseCaseProvider =
    Provider<SignOutWithFirebaseUseCase>((ref) {
  final repo = ref.watch(firebaseAuthRepositoryProvider);
  return SignOutWithFirebaseUseCase(repo);
});
