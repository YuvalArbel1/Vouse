// lib/domain/usecases/server/get_post_engagement_by_local_id_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/entities/server/post_engagement.dart';
import 'package:vouse_flutter/domain/repository/server/server_repository.dart';

/// Parameters for getting engagement for a specific post by local ID
class GetPostEngagementByLocalIdParams {
  final String postIdLocal;

  GetPostEngagementByLocalIdParams(this.postIdLocal);
}

/// A use case that retrieves engagement metrics for a specific post by local ID.
class GetPostEngagementByLocalIdUseCase
    extends UseCase<DataState<PostEngagement?>, GetPostEngagementByLocalIdParams> {
  final ServerRepository _repository;

  GetPostEngagementByLocalIdUseCase(this._repository);

  @override
  Future<DataState<PostEngagement?>> call({GetPostEngagementByLocalIdParams? params}) {
    if (params == null) {
      throw ArgumentError('GetPostEngagementByLocalIdParams cannot be null');
    }
    return _repository.getEngagementByLocalId(params.postIdLocal);
  }
}