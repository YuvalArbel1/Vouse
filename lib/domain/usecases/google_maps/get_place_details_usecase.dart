// lib/domain/usecases/location/get_place_details_usecase.dart

import 'package:dio/dio.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/core/usecases/usecase.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_details_entity.dart';

import '../../repository/google_maps/location_repository.dart';

class GetPlaceDetailsUseCase
    implements UseCase<DataState<PlaceDetailsEntity>, String> {
  final LocationRepository repository;

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


