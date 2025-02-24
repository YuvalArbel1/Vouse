// lib/presentation/providers/firebase/firebase_auth_notifier.dart

import 'package:riverpod/riverpod.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/usecases/auth/firebase/sign_in_with_firebase_usecase.dart';
import 'package:vouse_flutter/domain/usecases/auth/firebase/sign_up_with_firebase_usecase.dart';
import 'package:vouse_flutter/domain/usecases/auth/firebase/forgot_password_usecase.dart';
import 'package:vouse_flutter/domain/usecases/auth/firebase/is_email_verified_usecase.dart';
import 'package:vouse_flutter/domain/usecases/auth/firebase/send_email_verification_usecase.dart';
import 'package:vouse_flutter/domain/usecases/auth/firebase/sign_in_with_google_usecase.dart';
import '../../../../domain/usecases/auth/firebase/sign_out_with_firebase_usecase.dart';
import 'firebase_auth_providers.dart';

/// A [StateNotifierProvider] exposing a [FirebaseAuthNotifier] that handles all FirebaseAuth operations.
///
/// The [DataState<void>] type describes the state of the most recent auth action.
final firebaseAuthNotifierProvider =
    StateNotifierProvider<FirebaseAuthNotifier, DataState<void>>((ref) {
  final signInUC = ref.watch(signInWithFirebaseUseCaseProvider);
  final signUpUC = ref.watch(signUpWithFirebaseUseCaseProvider);
  final forgotPassUC = ref.watch(forgotPasswordUseCaseProvider);
  final sendVerUC = ref.watch(sendEmailVerificationUseCaseProvider);
  final checkVerUC = ref.watch(isEmailVerifiedUseCaseProvider);
  final signInWithGoogleUC = ref.watch(signInWithGoogleUseCaseProvider);
  final signOutUC = ref.watch(signOutWithFirebaseUseCaseProvider);

  return FirebaseAuthNotifier(
    signInUC,
    signUpUC,
    forgotPassUC,
    sendVerUC,
    checkVerUC,
    signInWithGoogleUC,
    signOutUC,
  );
});

/// A [StateNotifier] managing FirebaseAuth-related actions like sign-in, sign-up,
/// email verification, etc. The [state] is a [DataState<void>] describing the outcome
/// of the last operation (success/failure).
class FirebaseAuthNotifier extends StateNotifier<DataState<void>> {
  final SignInWithFirebaseUseCase _signInUseCase;
  final SignUpWithFirebaseUseCase _signUpUseCase;
  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final SendEmailVerificationUseCase _sendVerificationUseCase;
  final IsEmailVerifiedUseCase _isEmailVerifiedUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final SignOutWithFirebaseUseCase _signOutUseCase;

  /// Constructs a notifier with all needed Firebase-related use cases.
  FirebaseAuthNotifier(
    this._signInUseCase,
    this._signUpUseCase,
    this._forgotPasswordUseCase,
    this._sendVerificationUseCase,
    this._isEmailVerifiedUseCase,
    this._signInWithGoogleUseCase,
    this._signOutUseCase,
  ) : super(const DataSuccess(null));

  /// Signs in a user with [email] and [password].
  /// Sets [state] to [DataSuccess] or [DataFailed] depending on the result.
  Future<void> signIn(String email, String password) async {
    // Optionally set a loading state
    state = const DataSuccess(null);

    final result = await _signInUseCase(
      params: SignInWithFirebaseParams(email: email, password: password),
    );
    state = result;
  }

  /// Registers a new user with [email], [password], and sends a verification email.
  Future<void> signUp(String email, String password) async {
    state = const DataSuccess(null);

    final result = await _signUpUseCase(
      params: SignUpWithFirebaseParams(email: email, password: password),
    );
    state = result;
  }

  /// Sends a password reset email to [email].
  /// The returned [state] will reflect success/failure of that operation.
  Future<void> forgotPassword(String email) async {
    final result = await _forgotPasswordUseCase.call(
      params: ForgotPasswordParams(email: email),
    );
    state = result;
  }

  /// Sends another verification email for the currently logged-in user.
  /// If there's an error, sets [state] to [DataFailed]. Otherwise remains [DataSuccess].
  Future<void> sendVerificationEmail() async {
    state = const DataSuccess(null);

    final result = await _sendVerificationUseCase.call(params: null);
    if (result is DataFailed) {
      state = result;
    } else {
      state = const DataSuccess(null);
    }
  }

  /// Checks if the current user's email is verified. Returns a bool instead of updating [state].
  /// On error, returns false.
  Future<bool> checkEmailVerified() async {
    final result = await _isEmailVerifiedUseCase.call(params: null);

    if (result is DataSuccess<bool>) {
      return result.data ?? false;
    } else {
      return false;
    }
  }

  /// Signs in with Google. Updates [state] with success/failure.
  Future<void> signInWithGoogle() async {
    state = const DataSuccess(null);

    final result = await _signInWithGoogleUseCase.call(params: null);
    state = result;
  }

  /// Signs out the currently logged-in user. If successful, sets [state] to [DataSuccess].
  Future<void> signOut() async {
    state = const DataSuccess(null);

    final result = await _signOutUseCase.call(params: null);
    state = result;
  }
}
