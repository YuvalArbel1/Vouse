// lib/domain/usecases/location/get_current_location_usecase.dart

import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_location_entity.dart';

import '../../../core/usecases/usecase.dart';
import '../../repository/google_maps/location_repository.dart';

class GetCurrentLocationUseCase
    implements UseCase<DataState<PlaceLocationEntity>, void> {
  final LocationRepository repository;

  GetCurrentLocationUseCase(this.repository);

  @override
  Future<DataState<PlaceLocationEntity>> call({void params}) {
    return repository.getCurrentLocation();
  }
}
