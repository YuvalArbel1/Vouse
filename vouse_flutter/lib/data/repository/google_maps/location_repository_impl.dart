// lib/data/repositories/google_maps/location_repository_impl.dart

import 'package:location/location.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_location_entity.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_suggestion_entity.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_details_entity.dart';
import 'package:dio/dio.dart';

import '../../../domain/repository/google_maps/location_repository.dart';
import '../../data_sources/remote/google_maps/location_remote_data_source.dart';

/// Implements [LocationRepository] by combining local device location (via [location])
/// and remote Google Maps operations (via [remoteDataSource]).
class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource remoteDataSource;
  final Location location;

  /// Accepts a [LocationRemoteDataSource] for geocoding/autocomplete
  /// and a [Location] plugin instance for accessing device coordinates.
  LocationRepositoryImpl({
    required this.remoteDataSource,
    required this.location,
  });

  /// Requests the user's current location, enabling services and permissions if needed.
  ///
  /// Optionally reverse geocodes the coordinates to obtain an address. Returns
  /// [DataSuccess] with [PlaceLocationEntity] or [DataFailed] on errors.
  @override
  Future<DataState<PlaceLocationEntity>> getCurrentLocation() async {
    try {
      // Ensure the location service is enabled
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          return DataFailed<PlaceLocationEntity>(
            DioException(
              requestOptions: RequestOptions(path: ''),
              error: 'Location service disabled',
            ),
          );
        }
      }

      // Check location permission
      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return DataFailed<PlaceLocationEntity>(
            DioException(
              requestOptions: RequestOptions(path: ''),
              error: 'Location permission denied',
            ),
          );
        }
      }

      // Fetch coordinates
      final locationData = await location.getLocation();
      if (locationData.latitude == null || locationData.longitude == null) {
        return DataFailed<PlaceLocationEntity>(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Location data is null',
          ),
        );
      }

      // Reverse geocode coordinates (optional)
      final reverseResult = await remoteDataSource.reverseGeocode(
        locationData.latitude!,
        locationData.longitude!,
      );
      String? address;
      if (reverseResult is DataSuccess<String>) {
        address = reverseResult.data;
      }

      final entity = PlaceLocationEntity(
        latitude: locationData.latitude!,
        longitude: locationData.longitude!,
        address: address,
      );
      return DataSuccess<PlaceLocationEntity>(entity);
    } catch (e) {
      return DataFailed<PlaceLocationEntity>(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  /// Reverse geocodes [latitude], [longitude] to a human-readable address.
  @override
  Future<DataState<String>> reverseGeocode(double latitude, double longitude) {
    return remoteDataSource.reverseGeocode(latitude, longitude);
  }

  /// Uses Google Places autocomplete to suggest possible locations matching [query].
  @override
  Future<DataState<List<PlaceSuggestionEntity>>> autocompletePlaces(
      String query) {
    return remoteDataSource.autocompletePlaces(query);
  }

  /// Retrieves detailed info (lat/lng, name, etc.) for [placeId].
  @override
  Future<DataState<PlaceDetailsEntity>> getPlaceDetails(String placeId) {
    return remoteDataSource.getPlaceDetails(placeId);
  }
}
