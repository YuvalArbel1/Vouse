import 'package:vouse_flutter/core/resources/data_state.dart';

/// Defines the authentication contract for Firebase-based auth.
/// Each method returns a [DataState<T>] to indicate success or failure.
abstract class FirebaseAuthRepository {
  /// Signs in an existing user with email and password.
  Future<DataState<void>> signIn(String email, String password);

  /// Registers a new user with email, password, and sends verification email.
  Future<DataState<void>> signUp(String email, String password);

  /// Sends a password reset email (no error if email unregistered).
  Future<DataState<void>> forgotPassword(String email);

  /// Sends a new verification email to the currently signed-in user.
  Future<DataState<void>> sendEmailVerification();

  /// Reloads the user from server and checks if email is verified.
  /// Returns a [DataSuccess<bool>] with `true` if verified, `false` otherwise.
  Future<DataState<bool>> isEmailVerified();


  /// Sign in with google
  Future<DataState<void>> signInWithGoogle();

  /// Signs out the currently logged-in user.
  /// Returns a [DataSuccess<void>] if successful, or [DataFailed<void>] on error.
  Future<DataState<void>> signOut();

}
