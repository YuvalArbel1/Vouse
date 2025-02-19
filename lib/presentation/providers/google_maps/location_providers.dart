// lib/presentation/providers/location/location_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';
import 'package:dio/dio.dart';

import '../../../data/clients/google_maps/google_maps_service.dart';
import '../../../data/data_sources/remote/google_maps/location_remote_data_source.dart';
import '../../../data/repository/google_maps/location_repository_impl.dart';
import '../../../domain/repository/google_maps/location_repository.dart';
import '../../../domain/usecases/google_maps/get_current_location_usecase.dart';
import '../../../domain/usecases/google_maps/get_place_details_usecase.dart';
import '../../../domain/usecases/google_maps/reverse_geocode_usecase.dart';
import '../../../domain/usecases/google_maps/search_places_usecase.dart';


final dioProvider = Provider<Dio>((ref) => Dio());

final googleMapsServiceProvider = Provider<GoogleMapsService>((ref) {
  return GoogleMapsService(ref.watch(dioProvider));
});

final locationRemoteDataSourceProvider =
Provider<LocationRemoteDataSource>((ref) {
  return LocationRemoteDataSource(
    googleMapsService: ref.watch(googleMapsServiceProvider),
    apiKey: "AIzaSyD4wv4oFV3YrLZ7ZLWUJ0uDlO8BFtMoA7E", // your real key
  );
});

final locationPluginProvider = Provider<Location>((ref) {
  return Location();
});

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepositoryImpl(
    remoteDataSource: ref.watch(locationRemoteDataSourceProvider),
    location: ref.watch(locationPluginProvider),
  );
});

final getCurrentLocationUseCaseProvider =
Provider<GetCurrentLocationUseCase>((ref) {
  return GetCurrentLocationUseCase(ref.watch(locationRepositoryProvider));
});

final reverseGeocodeUseCaseProvider =
Provider<ReverseGeocodeUseCase>((ref) {
  return ReverseGeocodeUseCase(ref.watch(locationRepositoryProvider));
});


final searchPlacesUseCaseProvider = Provider<SearchPlacesUseCase>((ref) {
  return SearchPlacesUseCase(ref.watch(locationRepositoryProvider));
});

final getPlaceDetailsUseCaseProvider = Provider<GetPlaceDetailsUseCase>((ref) {
  return GetPlaceDetailsUseCase(ref.watch(locationRepositoryProvider));
});
