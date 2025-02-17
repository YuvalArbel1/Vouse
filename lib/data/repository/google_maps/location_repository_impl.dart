// lib/data/repositories/location_repository_impl.dart

import 'package:location/location.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_location_entity.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_suggestion_entity.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_details_entity.dart';
import 'package:dio/dio.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../domain/repository/google_maps/location_repository.dart';
import '../../data_sources/remote/google_maps/location_remote_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource remoteDataSource;
  final Location location;

  LocationRepositoryImpl({
    required this.remoteDataSource,
    required this.location,
  });

  @override
  Future<DataState<PlaceLocationEntity>> getCurrentLocation() async {
    try {
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

      final locationData = await location.getLocation();
      if (locationData.latitude == null || locationData.longitude == null) {
        return DataFailed<PlaceLocationEntity>(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Location data is null',
          ),
        );
      }

      // Optionally reverse geocode
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

  @override
  Future<DataState<String>> reverseGeocode(double latitude, double longitude) {
    return remoteDataSource.reverseGeocode(latitude, longitude);
  }

  // NEW: Autocomplete
  @override
  Future<DataState<List<PlaceSuggestionEntity>>> autocompletePlaces(String query) {
    return remoteDataSource.autocompletePlaces(query);
  }

  // NEW: Place details
  @override
  Future<DataState<PlaceDetailsEntity>> getPlaceDetails(String placeId) {
    return remoteDataSource.getPlaceDetails(placeId);
  }
}
