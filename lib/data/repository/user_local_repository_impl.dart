import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/entities/user_entity.dart';

import 'package:vouse_flutter/data/models/user_model.dart';
import 'package:dio/dio.dart';

import '../../domain/repository/home/user_local_repository.dart';
import '../data_sources/local.dart';

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
        xCredential: user.xCredential,
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
      return DataSuccess(userModel); // might be null if not found
    } catch (e) {
      return DataFailed(
        DioException(requestOptions: RequestOptions(path: ''), error: e),
      );
    }
  }
}
