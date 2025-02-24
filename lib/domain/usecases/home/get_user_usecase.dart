// lib/domain/usecases/home/get_user_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import '../../entities/local_db/user_entity.dart';
import '../../repository/local_db/user_local_repository.dart';

/// Holds a [userId] needed to retrieve the user from local storage.
class GetUserParams {
  final String userId;

  /// Creates params with a [userId] for lookup.
  GetUserParams(this.userId);
}

/// Retrieves a [UserEntity] from the local database by [userId].
///
/// Returns a [DataSuccess<UserEntity?>] if found, or [DataSuccess(null)] if
/// no user record matches. Returns [DataFailed] on any error.
class GetUserUseCase extends UseCase<DataState<UserEntity?>, GetUserParams> {
  final UserLocalRepository _repository;

  /// Requires a [UserLocalRepository] to access local DB operations.
  GetUserUseCase(this._repository);

  @override
  Future<DataState<UserEntity?>> call({GetUserParams? params}) {
    return _repository.getUser(params!.userId);
  }
}
