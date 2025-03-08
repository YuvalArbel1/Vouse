// lib/core/extensions/map_extensions.dart

extension MapJsonExtension on Map<String, dynamic> {
  static Map<String, dynamic> fromJson(Map<String, dynamic> json) {
    return json; // Simply return the json as it's already a Map<String, dynamic>
  }
}
