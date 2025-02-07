import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/repository/firebase_auth_repository.dart';

/// Implements the Firebase-specific authentication by using [FirebaseAuth].
/// On success, returns [DataSuccess(null)], on error returns [DataFailed(...)].
class FirebaseAuthRepositoryImpl implements FirebaseAuthRepository {
  final FirebaseAuth _firebaseAuth;

  const FirebaseAuthRepositoryImpl(this._firebaseAuth);

  @override
  Future<DataState<void>> signIn(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return const DataSuccess(null);
    } on FirebaseAuthException catch (e) {
      // Convert FirebaseAuthException to a user-friendly message
      final message = _getFirebaseAuthErrorMessage(e);
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: message,
        ),
      );
    } catch (e) {
      // Catch any other errors (e.g., unexpected)
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  @override
  Future<DataState<void>> signUp(String email, String password) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return const DataSuccess(null);
    } on FirebaseAuthException catch (e) {
      final message = _getFirebaseAuthErrorMessage(e);
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: message,
        ),
      );
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  /// Converts a [FirebaseAuthException] into a user-friendly message.
  /// This includes common codes from the Firebase Auth docs, but you can adjust
  /// or unify messages as you see fit.
  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
    // --- WRONG EMAIL/PASSWORD ---
    // We'll unify "invalid-email", "invalid-credential", "wrong-password", and
    // "user-not-found" under ONE message, so we don't give hints about
    // whether the email or password was incorrect.
      case 'invalid-email':
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'The email or password is invalid. Please try again.';

    // --- NETWORK / QUOTA ---
      case 'network-request-failed':
        return 'Network error! Please check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';

    // --- REGISTRATION-SPECIFIC ---
    // Typically occur in sign-up flows only.
      case 'weak-password':
        return 'Your password is too weak. Please choose a stronger one.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';

    // --- USER DISABLED, ETC. ---
      case 'user-disabled':
        return 'This user account has been disabled. Please contact support.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';

    // --- MISC ---
    // You can add more codes from the docs as needed (e.g. 'requires-recent-login', etc.)
      default:
      // Fallback to the exception's message or a generic error.
        return e.message ?? 'An unknown error occurred.';
    }
  }


}
