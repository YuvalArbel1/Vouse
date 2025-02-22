import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/entities/locaal%20db/user_entity.dart';

import '../../repository/local_db/user_local_repository.dart';

class SaveUserUseCase extends UseCase<DataState<void>, UserEntity> {
  final UserLocalRepository _repository;

  SaveUserUseCase(this._repository);

  @override
  Future<DataState<void>> call({UserEntity? params}) {
    return _repository.saveUser(params!);
  }
}
