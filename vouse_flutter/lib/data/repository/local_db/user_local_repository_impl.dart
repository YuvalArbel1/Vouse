// lib/data/repository/local_db/user_local_repository_impl.dart

import 'package:dio/dio.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/repository/local_db/user_local_repository.dart';
import 'package:vouse_flutter/data/models/local_db/user_model.dart';

import '../../../domain/entities/local_db/user_entity.dart';
import '../../data_sources/local/user_local_data_source.dart';

/// Implements [UserLocalRepository], performing local CRUD on the 'user' table
/// via [UserLocalDataSource].
class UserLocalRepositoryImpl implements UserLocalRepository {
  final UserLocalDataSource _localDataSource;

  /// Requires a [UserLocalDataSource] that handles the actual database reads/writes.
  UserLocalRepositoryImpl(this._localDataSource);

  /// Saves or updates [user] in the local DB.
  @override
  Future<DataState<void>> saveUser(UserEntity user) async {
    try {
      final userModel = UserModel(
        userId: user.userId,
        fullName: user.fullName,
        dateOfBirth: user.dateOfBirth,
        gender: user.gender,
        avatarPath: user.avatarPath,
      );
      await _localDataSource.insertOrUpdateUser(userModel);
      return const DataSuccess(null);
    } catch (e) {
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: e),
      );
    }
  }

  /// Retrieves a user by [userId], returning a [DataSuccess(UserEntity?)] or [DataFailed].
  @override
  Future<DataState<UserEntity?>> getUser(String userId) async {
    try {
      final userModel = await _localDataSource.getUserById(userId);
      // userModel might be null
      return DataSuccess(userModel);
    } catch (e) {
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: e),
      );
    }
  }
}
