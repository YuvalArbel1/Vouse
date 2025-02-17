// lib/domain/usecases/location/search_places_usecase.dart

import 'package:dio/dio.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_suggestion_entity.dart';

import '../../repository/google_maps/location_repository.dart';

class SearchPlacesParams {
  final String query;
  SearchPlacesParams(this.query);
}

class SearchPlacesUseCase
    implements UseCase<DataState<List<PlaceSuggestionEntity>>, SearchPlacesParams> {
  final LocationRepository repository;

  SearchPlacesUseCase(this.repository);

  @override
  Future<DataState<List<PlaceSuggestionEntity>>> call({
    SearchPlacesParams? params,
  }) async {
    if (params == null || params.query.isEmpty) {
      return DataFailed(
        DioException(
          message: 'Missing SearchPlacesParams',
          requestOptions: RequestOptions(path: ''),
        ),
      );
    }
    return repository.autocompletePlaces(params.query);
  }
}
