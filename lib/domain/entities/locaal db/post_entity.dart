class PostEntity {
  final String postIdLocal;
  final String? postIdX;
  final String content;
  final String title;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? scheduledAt;
  final String? visibility;
  final List<String> localImagePaths;
  final List<String> cloudImageUrls;
  final double? locationLat;
  final double? locationLng;
  final String? locationAddress;

  PostEntity({
    required this.postIdLocal,
    required this.postIdX,
    required this.content,
    required this.title,
    required this.createdAt,
    this.updatedAt,
    this.scheduledAt,
    this.visibility,
    required this.localImagePaths,
    required this.cloudImageUrls,
    this.locationLat,
    this.locationLng,
    this.locationAddress,
  });

  PostEntity copyWith({
    String? postIdLocal,
    String? postIdX,
    String? content,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? scheduledAt,
    String? visibility,
    List<String>? localImagePaths,
    List<String>? cloudImageUrls,
    double? locationLat,
    double? locationLng,
    String? locationAddress,
  }) {
    return PostEntity(
      postIdLocal: postIdLocal ?? this.postIdLocal,
      postIdX: postIdX ?? this.postIdX,
      content: content ?? this.content,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      visibility: visibility ?? this.visibility,
      localImagePaths: localImagePaths ?? this.localImagePaths,
      cloudImageUrls: cloudImageUrls ?? this.cloudImageUrls,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      locationAddress: locationAddress ?? this.locationAddress,
    );
  }
}
