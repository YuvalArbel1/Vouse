// lib/data/datasources/remote/google_maps/location_remote_data_source.dart

import 'package:dio/dio.dart';
import 'package:vouse_flutter/core/resources/data_state.dart';
import '../../../clients/google_maps/google_maps_service.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_suggestion_entity.dart';
import 'package:vouse_flutter/domain/entities/google_maps/place_details_entity.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Communicates with the Google Maps API to perform reverse geocoding,
/// place autocomplete, and place details requests.
class LocationRemoteDataSource {
  final GoogleMapsService googleMapsService;
  final String apiKey;

  /// Requires a [GoogleMapsService] and an [apiKey] to authenticate requests.
  LocationRemoteDataSource({
    required this.googleMapsService,
    required this.apiKey,
  });

  /// Converts [lat], [lng] to a human-readable address.
  ///
  /// Returns a [DataSuccess] with the address on success,
  /// or a [DataFailed] with an error on failure.
  Future<DataState<String>> reverseGeocode(double lat, double lng) async {
    try {
      final response =
          await googleMapsService.reverseGeocode('$lat,$lng', apiKey);
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final firstResult = data['results'][0];
          final address = firstResult['formatted_address'] as String;
          return DataSuccess(address);
        } else {
          return DataFailed(
            DioException(
              requestOptions: RequestOptions(path: ''),
              error: 'No results found',
            ),
          );
        }
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'Non-200 status code',
          ),
        );
      }
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  /// Returns autocomplete suggestions for [query].
  ///
  /// On success, returns [DataSuccess] with a list of [PlaceSuggestionEntity].
  /// On error or empty results, returns [DataFailed].
  Future<DataState<List<PlaceSuggestionEntity>>> autocompletePlaces(
      String query) async {
    try {
      final response = await googleMapsService.autocomplete(query, apiKey);
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          final suggestions = predictions.map((p) {
            return PlaceSuggestionEntity(
              placeId: p['place_id'],
              description: p['description'],
            );
          }).toList();
          return DataSuccess(suggestions);
        } else {
          return DataFailed(
            DioException(
              requestOptions: RequestOptions(path: ''),
              error: 'Places API Error: ${data['status']}',
            ),
          );
        }
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'HTTP ${response.response.statusCode}',
          ),
        );
      }
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }

  /// Retrieves place details for [placeId], returning a lat/lng via [PlaceDetailsEntity].
  ///
  /// On success, returns [DataSuccess] with [PlaceDetailsEntity].
  /// On error, returns [DataFailed].
  Future<DataState<PlaceDetailsEntity>> getPlaceDetails(String placeId) async {
    try {
      final response = await googleMapsService.getPlaceDetails(placeId, apiKey);
      if (response.response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          final result = data['result'];
          final geometry = result['geometry']['location'];
          final lat = geometry['lat'] as double;
          final lng = geometry['lng'] as double;

          final name = result['name'] as String?;
          final details = PlaceDetailsEntity(
            latLng: LatLng(lat, lng),
            name: name,
          );
          return DataSuccess(details);
        } else {
          return DataFailed(
            DioException(
              requestOptions: RequestOptions(path: ''),
              error: 'Place details error: ${data['status']}',
            ),
          );
        }
      } else {
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'HTTP ${response.response.statusCode}',
          ),
        );
      }
    } catch (e) {
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }
}
