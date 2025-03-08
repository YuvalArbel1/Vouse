// lib/domain/usecases/server/refresh_all_engagements_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/server/server_repository.dart';

/// A use case that forces a refresh of all engagement metrics.
class RefreshAllEngagementsUseCase
    extends UseCase<DataState<Map<String, dynamic>>, void> {
  final ServerRepository _repository;

  RefreshAllEngagementsUseCase(this._repository);

  @override
  Future<DataState<Map<String, dynamic>>> call({void params}) {
    return _repository.refreshAllEngagements();
  }
}