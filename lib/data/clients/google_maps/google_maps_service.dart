// lib/data/remote/google_maps_service.dart

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'google_maps_service.g.dart';

@RestApi(baseUrl: "https://maps.googleapis.com/maps/api")
abstract class GoogleMapsService {
  factory GoogleMapsService(Dio dio, {String baseUrl}) = _GoogleMapsService;

  // Example for reverse geocode
  @GET("/geocode/json")
  Future<HttpResponse<dynamic>> reverseGeocode(
      @Query("latlng") String latlng,
      @Query("key") String apiKey,
      );

  // Autocomplete
  @GET("/place/autocomplete/json")
  Future<HttpResponse<dynamic>> autocomplete(
      @Query("input") String input,
      @Query("key") String apiKey,
      // Optionally specify &types=geocode or locationbias, etc.
      );

  // Place details
  @GET("/place/details/json")
  Future<HttpResponse<dynamic>> getPlaceDetails(
      @Query("place_id") String placeId,
      @Query("key") String apiKey,
      );

}
