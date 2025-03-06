// lib/presentation/providers/auth/firebase/auth_state_provider.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vouse_flutter/presentation/providers/user/user_profile_provider.dart';

/// Enum representing different authentication states.
enum AuthState {
  /// Initial state before checking auth
  initial,

  /// User is authenticated
  authenticated,

  /// User is not authenticated
  unauthenticated,

  /// User is authenticated but email is not verified
  unverified,
}

/// A provider that streams the current authentication state.
///
/// This provider listens to Firebase Auth changes and maps them
/// to the [AuthState] enum for use throughout the app.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return FirebaseAuth.instance.authStateChanges().map((user) {
    if (user == null) {
      // Clear the user profile when logged out
      ref.read(userProfileProvider.notifier).clearUserProfile();
      return AuthState.unauthenticated;
    }

    if (!user.emailVerified) {
      return AuthState.unverified;
    }

    // When authenticated, load the user profile
    ref.read(userProfileProvider.notifier).loadUserProfile();
    return AuthState.authenticated;
  });
});

/// A provider that gives the current user ID safely.
///
/// Returns null if the user is not logged in.
final currentUserIdProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});

/// A provider that checks if the user is logged in.
final isUserLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state == AuthState.authenticated,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// A provider that checks if the user's email is verified.
final isEmailVerifiedProvider = Provider<bool>((ref) {
  return FirebaseAuth.instance.currentUser?.emailVerified ?? false;
});