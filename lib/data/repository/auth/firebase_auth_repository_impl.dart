import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/repository/auth/firebase_auth_repository.dart';

/// Implements Firebase Auth flows:
/// - signIn, signUp, forgotPassword
/// - email verification, check if verified
/// Each method returns a [DataState<T>] so the Notifier/UI can distinguish success/failure.
class FirebaseAuthRepositoryImpl implements FirebaseAuthRepository {
  final FirebaseAuth _firebaseAuth;

  /// Requires a [FirebaseAuth.instance], typically provided by your DI container.
  const FirebaseAuthRepositoryImpl(this._firebaseAuth);

  @override
  Future<DataState<void>> signIn(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      return const DataSuccess(null);
    } on FirebaseAuthException catch (e) {
      // Convert FirebaseAuthException to a user-friendly message.
      final message = _getFirebaseAuthErrorMessage(e);
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: message),
      );
    } catch (e) {
      // Catch any other unexpected errors.
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: e.toString()),
      );
    }
  }

  @override
  Future<DataState<void>> signUp(String email, String password) async {
    try {
      // 1) Create user account
      final userCred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2) Immediately send verification email
      await userCred.user?.sendEmailVerification();

      return const DataSuccess(null);
    } on FirebaseAuthException catch (e) {
      final message = _getFirebaseAuthErrorMessage(e);
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: message),
      );
    } catch (e) {
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: e.toString()),
      );
    }
  }

  @override
  Future<DataState<void>> sendEmailVerification() async {
    try {
      // If user is logged in, send a fresh verification
      await _firebaseAuth.currentUser?.sendEmailVerification();
      return const DataSuccess(null);
    } on FirebaseAuthException catch (e) {
      final message = _getFirebaseAuthErrorMessage(e);
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: message),
      );
    } catch (e) {
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: e.toString()),
      );
    }
  }

  @override
  Future<DataState<bool>> isEmailVerified() async {
    try {
      // Force-refresh user data from the server
      await _firebaseAuth.currentUser?.reload();
      // If currentUser is null, fallback to false
      final bool verified = _firebaseAuth.currentUser?.emailVerified ?? false;
      // Guarantee a non-null bool for DataSuccess
      return DataSuccess(verified);
    } catch (e) {
      // On error, return DataFailed
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: e.toString()),
      );
    }
  }

  @override
  Future<DataState<void>> forgotPassword(String email) async {
    try {
      // Always returns success, even if the email doesn't exist
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const DataSuccess(null);
    } on FirebaseAuthException catch (e) {
      final message = _getFirebaseAuthErrorMessage(e);
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: message),
      );
    } catch (e) {
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: e.toString()),
      );
    }
  }

  /// NEW: Sign in with Google using [google_sign_in] package + FirebaseAuth credentials.
  @override
  Future<DataState<void>> signInWithGoogle() async {
    try {
      // 1) Launch the Google Sign-In flow
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Google sign-in aborted by user.',
          ),
        );
      }

      // 2) Obtain the Google auth details
      final googleAuth = await googleUser.authentication;

      // 3) Create a credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4) Sign in to Firebase
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

  /// Converts [FirebaseAuthException] codes into user-friendly messages
  /// or lumps them into a generic fallback.
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
      // Fallback to e.message or a generic error
        return e.message ?? 'An unknown error occurred.';
    }
  }
}
