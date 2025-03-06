// lib/domain/repository/auth/firebase_auth_repository.dart

import 'package:vouse_flutter/core/resources/data_state.dart';

/// Contract for Firebase-based authentication flows.
///
/// Each method returns a [DataState<T>] to consistently handle success/failure.
abstract class FirebaseAuthRepository {
  /// Signs in an existing user with [email] and [password].
  Future<DataState<void>> signIn(String email, String password);

  /// Registers a new user with [email], [password], and sends a verification email.
  Future<DataState<void>> signUp(String email, String password);

  /// Sends a password reset email to [email].
  /// Returns success even if the email isn't registered.
  Future<DataState<void>> forgotPassword(String email);

  /// Sends a fresh verification email to the currently signed-in user.
  Future<DataState<void>> sendEmailVerification();

  /// Checks if the currently signed-in user's email is verified.
  /// Returns [DataSuccess(true)] if verified, [DataSuccess(false)] otherwise.
  Future<DataState<bool>> isEmailVerified();

  /// Initiates sign-in via Google (using Google Sign-In + Firebase).
  Future<DataState<void>> signInWithGoogle();

  /// Signs out the currently logged-in user.
  /// Returns [DataSuccess<void>] on success, or [DataFailed<void>] on error.
  Future<DataState<void>> signOut();
}
