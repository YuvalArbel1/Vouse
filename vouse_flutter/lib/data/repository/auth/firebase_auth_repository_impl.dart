// lib/data/repository/auth/firebase_auth_repository_impl.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/repository/auth/firebase_auth_repository.dart';

/// Implements FirebaseAuth-based sign-in, sign-up, and related flows.
/// Each method returns a [DataState] to indicate success or failure.
class FirebaseAuthRepositoryImpl implements FirebaseAuthRepository {
  final FirebaseAuth _firebaseAuth;

  /// Requires an initialized [FirebaseAuth] instance.
  const FirebaseAuthRepositoryImpl(this._firebaseAuth);

  /// Signs in a user with [email] and [password].
  ///
  /// If the user is not email-verified, sends another verification email
  /// and returns a [DataFailed] with 'EMAIL_NOT_VERIFIED'.
  /// Otherwise, returns [DataSuccess] on success.
  @override
  Future<DataState<void>> signIn(String email, String password) async {
    try {
      final userCred = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!(userCred.user?.emailVerified ?? false)) {
        await userCred.user?.sendEmailVerification();
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'EMAIL_NOT_VERIFIED',
          ),
        );
      }
      return const DataSuccess(null);
    } on FirebaseAuthException catch (e) {
      final message = _getFirebaseAuthErrorMessage(e);
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: message),
      );
    } catch (e) {
      return DataFailed(
        DioException(
            requestOptions: RequestOptions(path: ''), error: e.toString()),
      );
    }
  }

  /// Registers a user with [email] and [password], then sends a verification email.
  /// Returns [DataSuccess] on success, or [DataFailed] on error.
  @override
  Future<DataState<void>> signUp(String email, String password) async {
    try {
      final userCred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCred.user?.sendEmailVerification();
      return const DataSuccess(null);
    } on FirebaseAuthException catch (e) {
      final message = _getFirebaseAuthErrorMessage(e);
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: message),
      );
    } catch (e) {
      return DataFailed(
        DioException(
            requestOptions: RequestOptions(path: ''), error: e.toString()),
      );
    }
  }

  /// Sends a new verification email to the current user if logged in.
  @override
  Future<DataState<void>> sendEmailVerification() async {
    try {
      await _firebaseAuth.currentUser?.sendEmailVerification();
      return const DataSuccess(null);
    } on FirebaseAuthException catch (e) {
      final message = _getFirebaseAuthErrorMessage(e);
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: message),
      );
    } catch (e) {
      return DataFailed(
        DioException(
            requestOptions: RequestOptions(path: ''), error: e.toString()),
      );
    }
  }

  /// Reloads the current user and checks [emailVerified].
  /// Returns [DataSuccess(true)] if verified, [DataSuccess(false)] otherwise.
  @override
  Future<DataState<bool>> isEmailVerified() async {
    try {
      await _firebaseAuth.currentUser?.reload();
      final verified = _firebaseAuth.currentUser?.emailVerified ?? false;
      return DataSuccess(verified);
    } catch (e) {
      return DataFailed(
        DioException(
            requestOptions: RequestOptions(path: ''), error: e.toString()),
      );
    }
  }

  /// Sends a password reset email to [email].
  /// Returns [DataSuccess] on success or [DataFailed] on error.
  @override
  Future<DataState<void>> forgotPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const DataSuccess(null);
    } on FirebaseAuthException catch (e) {
      final message = _getFirebaseAuthErrorMessage(e);
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: message),
      );
    } catch (e) {
      return DataFailed(
        DioException(
            requestOptions: RequestOptions(path: ''), error: e.toString()),
      );
    }
  }

  /// Sign in with Google using [google_sign_in], converting to Firebase credentials.
  /// Returns [DataSuccess] on success or [DataFailed] with an error message on failure.
  @override
  Future<DataState<void>> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Google sign-in aborted by user.',
          ),
        );
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _firebaseAuth.signInWithCredential(credential);
      return const DataSuccess(null);
    } on FirebaseAuthException catch (e) {
      final message = _getFirebaseAuthErrorMessage(e);
      return DataFailed(DioException(
        requestOptions: RequestOptions(path: ''),
        error: message,
      ));
    } catch (e) {
      return DataFailed(DioException(
        requestOptions: RequestOptions(path: ''),
        error: e.toString(),
      ));
    }
  }

  /// Signs out the currently logged-in user.
  @override
  Future<DataState<void>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return const DataSuccess(null);
    } catch (e) {
      return DataFailed(
        DioException(
            requestOptions: RequestOptions(path: ''), error: e.toString()),
      );
    }
  }

  /// Maps [FirebaseAuthException] codes to user-friendly messages.
  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
      case 'invalid-credential':
      case 'wrong-password':
        return 'The email or password is invalid. Please try again.';

      case 'user-not-found':
        return 'No user found with that email address.';
      case 'network-request-failed':
        return 'Network error! Please check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'weak-password':
        return 'Your password is too weak. Please choose a stronger one.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-disabled':
        return 'This user account has been disabled. Please contact support.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }
}
