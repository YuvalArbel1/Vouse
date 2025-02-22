import 'package:dio/dio.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/entities/locaal%20db/user_entity.dart';
import 'package:vouse_flutter/domain/repository/local_db/user_local_repository.dart';
import 'package:vouse_flutter/data/models/local_db/user_model.dart';

import '../../clients/local_db/local_database.dart';


class UserLocalRepositoryImpl implements UserLocalRepository {
  final UserLocalDataSource _localDataSource;

  UserLocalRepositoryImpl(this._localDataSource);

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
