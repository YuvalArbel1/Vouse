// lib/domain/usecases/server/refresh_post_engagement_by_local_id_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/entities/server/post_engagement.dart';
import 'package:vouse_flutter/domain/repository/server/server_repository.dart';

/// Parameters for refreshing engagement for a specific post by local ID
class RefreshPostEngagementByLocalIdParams {
  final String postIdLocal;

  RefreshPostEngagementByLocalIdParams(this.postIdLocal);
}

/// A use case that forces a refresh of engagement metrics for a specific post by local ID.
class RefreshPostEngagementByLocalIdUseCase
    extends UseCase<DataState<PostEngagement?>, RefreshPostEngagementByLocalIdParams> {
  final ServerRepository _repository;

  RefreshPostEngagementByLocalIdUseCase(this._repository);

  @override
  Future<DataState<PostEngagement?>> call({RefreshPostEngagementByLocalIdParams? params}) {
    if (params == null) {
      throw ArgumentError('RefreshPostEngagementByLocalIdParams cannot be null');
    }
    return _repository.refreshEngagementByLocalId(params.postIdLocal);
  }
}