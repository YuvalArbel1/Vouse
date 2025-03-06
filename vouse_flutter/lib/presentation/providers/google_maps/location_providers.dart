// lib/presentation/providers/google_maps/location_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';
import 'package:dio/dio.dart';

import 'package:vouse_flutter/core/config/app_secrets.dart';
import '../../../data/clients/google_maps/google_maps_service.dart';
import '../../../data/data_sources/remote/google_maps/location_remote_data_source.dart';
import '../../../data/repository/google_maps/location_repository_impl.dart';
import '../../../domain/repository/google_maps/location_repository.dart';
import '../../../domain/usecases/google_maps/get_current_location_usecase.dart';
import '../../../domain/usecases/google_maps/get_place_details_usecase.dart';
import '../../../domain/usecases/google_maps/reverse_geocode_usecase.dart';
import '../../../domain/usecases/google_maps/search_places_usecase.dart';

/// Provides a shared [Dio] instance for network requests.
final dioProvider = Provider<Dio>((ref) => Dio());

/// Creates a [GoogleMapsService] using the provided [dioProvider].
final googleMapsServiceProvider = Provider<GoogleMapsService>((ref) {
  return GoogleMapsService(ref.watch(dioProvider));
});

/// Builds a [LocationRemoteDataSource], injecting the [GoogleMapsService]
/// and a Google Maps API key from [AppSecrets].
final locationRemoteDataSourceProvider =
    Provider<LocationRemoteDataSource>((ref) {
  return LocationRemoteDataSource(
    googleMapsService: ref.watch(googleMapsServiceProvider),
    apiKey: AppSecrets.googleMapsApiKey, // use your real key from secrets
  );
});

/// Provides an instance of the [Location] plugin for device location access.
final locationPluginProvider = Provider<Location>((ref) {
  return Location();
});

/// Supplies a [LocationRepository] implementation combining local device location
/// (via [locationPluginProvider]) and remote data (via [locationRemoteDataSourceProvider]).
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepositoryImpl(
    remoteDataSource: ref.watch(locationRemoteDataSourceProvider),
    location: ref.watch(locationPluginProvider),
  );
});

/// Creates a [GetCurrentLocationUseCase] for retrieving the user's current device location.
final getCurrentLocationUseCaseProvider =
    Provider<GetCurrentLocationUseCase>((ref) {
  return GetCurrentLocationUseCase(ref.watch(locationRepositoryProvider));
});

/// Creates a [ReverseGeocodeUseCase] for converting coordinates to an address.
final reverseGeocodeUseCaseProvider = Provider<ReverseGeocodeUseCase>((ref) {
  return ReverseGeocodeUseCase(ref.watch(locationRepositoryProvider));
});

/// Creates a [SearchPlacesUseCase] for querying autocomplete place suggestions.
final searchPlacesUseCaseProvider = Provider<SearchPlacesUseCase>((ref) {
  return SearchPlacesUseCase(ref.watch(locationRepositoryProvider));
});

/// Creates a [GetPlaceDetailsUseCase] for looking up place details (lat/long, name, etc.).
final getPlaceDetailsUseCaseProvider = Provider<GetPlaceDetailsUseCase>((ref) {
  return GetPlaceDetailsUseCase(ref.watch(locationRepositoryProvider));
});
