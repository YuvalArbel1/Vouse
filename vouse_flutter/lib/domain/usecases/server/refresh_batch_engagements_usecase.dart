import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/repository/server/server_repository.dart';

/// Parameters for batch refreshing engagements
class RefreshBatchEngagementsParams {
  final List<String> postIds;

  RefreshBatchEngagementsParams(this.postIds);
}

/// A use case that refreshes engagement metrics for multiple posts at once.
class RefreshBatchEngagementsUseCase
    extends UseCase<DataState<Map<String, dynamic>>, RefreshBatchEngagementsParams> {
  final ServerRepository _repository;

  RefreshBatchEngagementsUseCase(this._repository);

  @override
  Future<DataState<Map<String, dynamic>>> call({RefreshBatchEngagementsParams? params}) {
    if (params == null) {
      throw ArgumentError('RefreshBatchEngagementsParams cannot be null');
    }
    return _repository.refreshBatchEngagements(params.postIds);
  }
}