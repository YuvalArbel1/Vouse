// lib/domain/usecases/google_maps/get_place_details_usecase.dart

import 'package:dio/dio.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_details_entity.dart';
import '../../repository/google_maps/location_repository.dart';

/// Fetches detailed information (coordinates, name, etc.) for a given place ID.
///
/// If [params] is null or empty, returns a [DataFailed] with a missing place ID message.
class GetPlaceDetailsUseCase
    implements UseCase<DataState<PlaceDetailsEntity>, String> {
  final LocationRepository repository;

  /// Requires a [LocationRepository] capable of looking up place details.
  GetPlaceDetailsUseCase(this.repository);

  @override
  Future<DataState<PlaceDetailsEntity>> call({String? params}) async {
    if (params == null || params.isEmpty) {
      return DataFailed(
        DioException(
          message: 'Missing place ID',
          requestOptions: RequestOptions(path: ''),
        ),
      );
    }
    return repository.getPlaceDetails(params);
  }
}
