// lib/presentation/providers/firebase_auth_notifier.dart

import 'package:riverpod/riverpod.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/usecases/auth/sign_in_with_firebase_usecase.dart';
import 'package:vouse_flutter/domain/usecases/auth/sign_up_with_firebase_usecase.dart';
import 'package:vouse_flutter/domain/usecases/auth/forgot_password_usecase.dart';
import 'package:vouse_flutter/domain/usecases/auth/is_email_verified_usecase.dart';
import 'package:vouse_flutter/domain/usecases/auth/send_email_verification_usecase.dart';
import 'package:vouse_flutter/domain/usecases/auth/sign_in_with_google_usecase.dart';
import 'firebase_auth_providers.dart';

/// A [StateNotifier] that holds a [DataState<void>] describing the last
/// auth operation (sign in, sign up, etc.).
///
/// We also provide methods like [checkEmailVerified] which returns a bool
/// instead of updating [state] with [DataSuccess<bool>].
final firebaseAuthNotifierProvider =
StateNotifierProvider<FirebaseAuthNotifier, DataState<void>>((ref) {
  final signInUC    = ref.watch(signInWithFirebaseUseCaseProvider);
  final signUpUC    = ref.watch(signUpWithFirebaseUseCaseProvider);
  final forgotPassUC= ref.watch(forgotPasswordUseCaseProvider);
  final sendVerUC   = ref.watch(sendEmailVerificationUseCaseProvider);
  final checkVerUC  = ref.watch(isEmailVerifiedUseCaseProvider);
  final signInWithGoogleUC = ref.watch(signInWithGoogleUseCaseProvider);


  return FirebaseAuthNotifier(
    signInUC,
    signUpUC,
    forgotPassUC,
    sendVerUC,
    checkVerUC,
    signInWithGoogleUC,
  );
});

class FirebaseAuthNotifier extends StateNotifier<DataState<void>> {
  final SignInWithFirebaseUseCase _signInUseCase;
  final SignUpWithFirebaseUseCase _signUpUseCase;
  final ForgotPasswordUseCase     _forgotPasswordUseCase;
  final SendEmailVerificationUseCase _sendVerificationUseCase;
  final IsEmailVerifiedUseCase       _isEmailVerifiedUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;


  FirebaseAuthNotifier(
      this._signInUseCase,
      this._signUpUseCase,
      this._forgotPasswordUseCase,
      this._sendVerificationUseCase,
      this._isEmailVerifiedUseCase,
      this._signInWithGoogleUseCase,
      ) : super(const DataSuccess(null));

  /// Attempts to sign in a user; updates [state] with success or failure.
  Future<void> signIn(String email, String password) async {
    state = const DataSuccess(null); // or show loading if you prefer
    final result = await _signInUseCase(
      params: SignInWithFirebaseParams(email: email, password: password),
    );
    // result is DataSuccess<void> or DataFailed<void>
    state = result;
  }

  /// Attempts to create a new user and send verification email.
  Future<void> signUp(String email, String password) async {
    state = const DataSuccess(null);
    final result = await _signUpUseCase(
      params: SignUpWithFirebaseParams(email: email, password: password),
    );
    state = result;
  }

  /// Sends a password reset email to [email].
  Future<void> forgotPassword(String email) async {
    final result = await _forgotPasswordUseCase.call(
      params: ForgotPasswordParams(email: email),
    );
    // store success or fail in [state]
    state = result;
  }

  /// Manually trigger another verification email for the currently logged-in user.
  Future<void> sendVerificationEmail() async {
    // Set a loading or success first
    state = const DataSuccess(null);

    final result = await _sendVerificationUseCase.call(params: null);
    if (result is DataFailed) {
      // If error, store the fail state
      state = result;
    } else {
      // On success, keep DataSuccess
      state = const DataSuccess(null);
    }
  }

  /// Checks if the current user's email is verified by reloading from the server.
  /// Returns `true` if verified, or `false` if not verified or error.
  Future<bool> checkEmailVerified() async {
    final result = await _isEmailVerifiedUseCase.call(params: null);

    if (result is DataSuccess<bool>) {
      // If DataSuccess, we have a non-nullable bool in .data
      return result.data!;
    } else {
      // If DataFailed, we just treat it as "not verified"
      return false;
    }
  }

  Future<void> signInWithGoogle() async {
    // Optionally set a loading state
    state = const DataSuccess(null);

    // Call the use case
    final result = await _signInWithGoogleUseCase.call(params: null);

    // result is DataSuccess<void> or DataFailed<void>
    state = result;
  }
}
