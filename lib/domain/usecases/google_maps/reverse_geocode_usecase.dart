// lib/domain/usecases/location/reverse_geocode_usecase.dart

import 'package:dio/dio.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import '../../../core/usecases/usecase.dart';
import '../../repository/google_maps/location_repository.dart';

class ReverseGeocodeParams {
  final double latitude;
  final double longitude;

  ReverseGeocodeParams(this.latitude, this.longitude);
}

class ReverseGeocodeUseCase
    implements UseCase<DataState<String>, ReverseGeocodeParams> {
  final LocationRepository repository;

  ReverseGeocodeUseCase(this.repository);

  @override
  Future<DataState<String>> call({ReverseGeocodeParams? params}) {
    // Expect non-null "params"
    final lat = params?.latitude;
    final lng = params?.longitude;
    if (lat == null || lng == null) {
      // Return DataFailed or throw an exception
      return Future.value(
        DataFailed<String>(
          DioException(
              message: 'Missing ReverseGeocodeParams',
              requestOptions: RequestOptions(path: '')),
        ),
      );
    }

    return repository.reverseGeocode(lat, lng);
  }
}
