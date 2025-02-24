// lib/domain/usecases/home/save_user_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import '../../entities/local_db/user_entity.dart';
import '../../repository/local_db/user_local_repository.dart';

/// Saves or updates a [UserEntity] in local storage.
class SaveUserUseCase extends UseCase<DataState<void>, UserEntity> {
  final UserLocalRepository _repository;

  /// Expects a [UserLocalRepository] to handle the actual insertion or update.
  SaveUserUseCase(this._repository);

  @override
  Future<DataState<void>> call({UserEntity? params}) {
    return _repository.saveUser(params!);
  }
}
