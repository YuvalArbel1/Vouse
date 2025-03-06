// lib/data/clients/google_maps/google_maps_service.dart

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'google_maps_service.g.dart';

/// A Retrofit-powered client for Google Maps APIs.
///
/// Provides methods for reverse geocoding, autocomplete, and place details.
@RestApi(baseUrl: "https://maps.googleapis.com/maps/api")
abstract class GoogleMapsService {
  factory GoogleMapsService(Dio dio, {String baseUrl}) = _GoogleMapsService;

  /// Reverse-geocodes [latlng] using [apiKey].
  @GET("/geocode/json")
  Future<HttpResponse<dynamic>> reverseGeocode(
    @Query("latlng") String latlng,
    @Query("key") String apiKey,
  );

  /// Fetches autocomplete suggestions for [input] using [apiKey].
  @GET("/place/autocomplete/json")
  Future<HttpResponse<dynamic>> autocomplete(
    @Query("input") String input,
    @Query("key") String apiKey,
  );

  /// Retrieves details for [placeId] using [apiKey].
  @GET("/place/details/json")
  Future<HttpResponse<dynamic>> getPlaceDetails(
    @Query("place_id") String placeId,
    @Query("key") String apiKey,
  );
}
