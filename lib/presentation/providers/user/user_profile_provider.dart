// lib/presentation/providers/user/user_profile_provider.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/entities/local_db/user_entity.dart';
import 'package:vouse_flutter/domain/usecases/home/get_user_usecase.dart';
import 'package:vouse_flutter/domain/usecases/home/save_user_usecase.dart';
import 'package:vouse_flutter/presentation/providers/local_db/local_user_providers.dart';

/// The loading states for the user profile
enum UserProfileLoadingState {
  /// Initial state
  initial,

  /// Loading the user profile
  loading,

  /// Successfully loaded the user profile
  loaded,

  /// Failed to load the user profile
  error
}

/// State for the user profile provider
class UserProfileState {
  /// The user entity
  final UserEntity? user;

  /// The current loading state
  final UserProfileLoadingState loadingState;

  /// Error message if loading failed
  final String? errorMessage;

  /// Creates a user profile state
  const UserProfileState({
    this.user,
    this.loadingState = UserProfileLoadingState.initial,
    this.errorMessage,
  });

  /// Creates a copy of this state with the given fields replaced
  UserProfileState copyWith({
    UserEntity? user,
    UserProfileLoadingState? loadingState,
    String? errorMessage,
  }) {
    return UserProfileState(
      user: user ?? this.user,
      loadingState: loadingState ?? this.loadingState,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// A notifier that manages the user profile state
class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final GetUserUseCase _getUserUseCase;
  final SaveUserUseCase _saveUserUseCase;

  // Track if we've attempted to load the profile
  bool _hasAttemptedInitialLoad = false;

  /// Creates a user profile notifier
  UserProfileNotifier(this._getUserUseCase, this._saveUserUseCase)
      : super(const UserProfileState());

  /// Loads the user profile for the current user
  Future<DataState<UserEntity?>> loadUserProfile() async {
    // Prevent multiple simultaneous loading attempts
    if (state.loadingState == UserProfileLoadingState.loading) {
      return const DataSuccess(null);
    }

    _hasAttemptedInitialLoad = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = state.copyWith(
        loadingState: UserProfileLoadingState.error,
        errorMessage: 'No user logged in',
      );
      return const DataSuccess(null);
    }

    // Set loading state
    state = state.copyWith(loadingState: UserProfileLoadingState.loading);

    try {
      final result =
          await _getUserUseCase.call(params: GetUserParams(user.uid));

      if (result is DataSuccess<UserEntity?>) {
        state = state.copyWith(
          user: result.data,
          loadingState: UserProfileLoadingState.loaded,
        );
        return result;
      } else if (result is DataFailed<UserEntity?>) {
        state = state.copyWith(
          loadingState: UserProfileLoadingState.error,
          errorMessage: result.error?.error.toString() ?? 'Unknown error',
        );
        return result;
      }

      return const DataSuccess(null);
    } catch (e) {
      state = state.copyWith(
        loadingState: UserProfileLoadingState.error,
        errorMessage: e.toString(),
      );
      return DataFailed(
        DioException(error: e, requestOptions: RequestOptions(path: '')),
      );
    }
  }

  /// Updates the user profile
  Future<DataState<void>> updateUserProfile(UserEntity updatedUser) async {
    state = state.copyWith(loadingState: UserProfileLoadingState.loading);

    final result = await _saveUserUseCase.call(params: updatedUser);

    if (result is DataSuccess<void>) {
      state = state.copyWith(
        user: updatedUser,
        loadingState: UserProfileLoadingState.loaded,
      );
    } else if (result is DataFailed<void>) {
      state = state.copyWith(
        loadingState: UserProfileLoadingState.error,
        errorMessage: result.error?.error.toString() ?? 'Unknown error',
      );
    }

    return result;
  }

  /// Updates the user's avatar path
  Future<DataState<void>> updateUserAvatar(String? newAvatarPath) async {
    if (state.user == null) {
      return DataFailed(
        DioException(
            error: 'No user profile loaded',
            requestOptions: RequestOptions(path: '')),
      );
    }

    final updatedUser = UserEntity(
      userId: state.user!.userId,
      fullName: state.user!.fullName,
      dateOfBirth: state.user!.dateOfBirth,
      gender: state.user!.gender,
      avatarPath: newAvatarPath,
    );

    return updateUserProfile(updatedUser);
  }

  /// Clears the user profile state (e.g., on logout)
  void clearUserProfile() {
    _hasAttemptedInitialLoad = false;
    state = const UserProfileState(
      loadingState: UserProfileLoadingState.initial,
    );
  }

  /// Check if we have attempted to load the profile
  bool get hasAttemptedInitialLoad => _hasAttemptedInitialLoad;
}

/// Provider for the user profile state
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
  final getUserUseCase = ref.watch(getUserUseCaseProvider);
  final saveUserUseCase = ref.watch(saveUserUseCaseProvider);
  return UserProfileNotifier(getUserUseCase, saveUserUseCase);
});

/// Provider for triggering user profile loading
final loadUserProfileProvider =
    FutureProvider<DataState<UserEntity?>>((ref) async {
  final getUserUseCase = ref.watch(getUserUseCaseProvider);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return const DataSuccess(null);
  }
  return await getUserUseCase.call(params: GetUserParams(user.uid));
});

/// Provider to check if a user has a profile
final hasProfileProvider = Provider<bool>((ref) {
  final profileState = ref.watch(userProfileProvider);
  return profileState.user != null;
});
