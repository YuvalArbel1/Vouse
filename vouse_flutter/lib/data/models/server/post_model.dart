// lib/data/models/server/post_model.dart

import 'package:vouse_flutter/domain/entities/local_db/post_entity.dart';

/// Status values for posts on the server
enum ServerPostStatus {
  draft,
  scheduled,
  publishing,
  published,
  failed,
}

/// Extension to convert string status to enum
extension ServerPostStatusExt on String {
  ServerPostStatus toServerPostStatus() {
    switch (this) {
      case 'draft':
        return ServerPostStatus.draft;
      case 'scheduled':
        return ServerPostStatus.scheduled;
      case 'publishing':
        return ServerPostStatus.publishing;
      case 'published':
        return ServerPostStatus.published;
      case 'failed':
        return ServerPostStatus.failed;
      default:
        throw Exception('Unknown post status: $this');
    }
  }
}

/// Extension to convert enum to string
extension ServerPostStatusValue on ServerPostStatus {
  String toValue() {
    switch (this) {
      case ServerPostStatus.draft:
        return 'draft';
      case ServerPostStatus.scheduled:
        return 'scheduled';
      case ServerPostStatus.publishing:
        return 'publishing';
      case ServerPostStatus.published:
        return 'published';
      case ServerPostStatus.failed:
        return 'failed';
    }
  }
}

/// Model representing a post on our server.
///
/// This closely matches the Post entity on the server side.
class ServerPostModel {
  final String? id; // Server ID (null for new posts)
  final String postIdLocal; // Generated UUID from app
  final String? postIdX; // Twitter ID (null until published)
  final String content; // Tweet text
  final String? title; // For organization only
  final DateTime? scheduledAt; // When post is scheduled
  final DateTime? publishedAt; // When post was published
  final ServerPostStatus? status; // Post status
  final String? failureReason; // Reason for failure if status is failed
  final String? visibility; // Twitter visibility setting
  final List<String> cloudImageUrls; // Firebase Storage URLs
  final double? locationLat; // Optional latitude
  final double? locationLng; // Optional longitude
  final String? locationAddress; // Optional human-readable location

  ServerPostModel({
    this.id,
    required this.postIdLocal,
    this.postIdX,
    required this.content,
    this.title,
    this.scheduledAt,
    this.publishedAt,
    this.status,
    this.failureReason,
    this.visibility,
    this.cloudImageUrls = const [],
    this.locationLat,
    this.locationLng,
    this.locationAddress,
  });

  factory ServerPostModel.fromJson(Map<String, dynamic> json) {
    return ServerPostModel(
      id: json['id'] as String?,
      postIdLocal: json['postIdLocal'] as String,
      postIdX: json['postIdX'] as String?,
      content: json['content'] as String,
      title: json['title'] as String?,
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'] as String)
          : null,
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'] as String)
          : null,
      status: json['status'] != null
          ? (json['status'] as String).toServerPostStatus()
          : null,
      failureReason: json['failureReason'] as String?,
      visibility: json['visibility'] as String?,
      cloudImageUrls: json['cloudImageUrls'] != null
          ? List<String>.from(json['cloudImageUrls'] as List)
          : const [],
      locationLat: json['locationLat'] != null
          ? (json['locationLat'] as num).toDouble()
          : null,
      locationLng: json['locationLng'] != null
          ? (json['locationLng'] as num).toDouble()
          : null,
      locationAddress: json['locationAddress'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['postIdLocal'] = postIdLocal;
    data['content'] = content;

    if (id != null) data['id'] = id;
    if (postIdX != null) data['postIdX'] = postIdX;
    if (title != null) data['title'] = title;
    if (scheduledAt != null) {
      data['scheduledAt'] = scheduledAt!.toUtc().toIso8601String();
    }
    if (status != null) data['status'] = status!.toValue();
    if (visibility != null) data['visibility'] = visibility;
    data['cloudImageUrls'] = cloudImageUrls;
    if (locationLat != null) data['locationLat'] = locationLat;
    if (locationLng != null) data['locationLng'] = locationLng;
    if (locationAddress != null) data['locationAddress'] = locationAddress;

    return data;
  }

  /// Creates a [ServerPostModel] from a local [PostEntity]
  factory ServerPostModel.fromPostEntity(PostEntity entity) {
    return ServerPostModel(
      postIdLocal: entity.postIdLocal,
      postIdX: entity.postIdX,
      content: entity.content,
      title: entity.title,
      scheduledAt: entity.scheduledAt,
      visibility: entity.visibility,
      cloudImageUrls: entity.cloudImageUrls,
      locationLat: entity.locationLat,
      locationLng: entity.locationLng,
      locationAddress: entity.locationAddress,
    );
  }

  /// Converts this server model to a local [PostEntity]
  PostEntity toPostEntity() {
    return PostEntity(
      postIdLocal: postIdLocal,
      postIdX: postIdX,
      content: content,
      title: title!,
      createdAt: publishedAt ?? DateTime.now(),
      updatedAt: publishedAt,
      scheduledAt: scheduledAt,
      visibility: visibility,
      localImagePaths: const [],
      // Server doesn't store local paths
      cloudImageUrls: cloudImageUrls,
      locationLat: locationLat,
      locationLng: locationLng,
      locationAddress: locationAddress,
    );
  }

  /// Creates a copy of this model with the given fields replaced
  ServerPostModel copyWith({
    String? id,
    String? postIdLocal,
    String? postIdX,
    String? content,
    String? title,
    DateTime? scheduledAt,
    DateTime? publishedAt,
    ServerPostStatus? status,
    String? failureReason,
    String? visibility,
    List<String>? cloudImageUrls,
    double? locationLat,
    double? locationLng,
    String? locationAddress,
  }) {
    return ServerPostModel(
      id: id ?? this.id,
      postIdLocal: postIdLocal ?? this.postIdLocal,
      postIdX: postIdX ?? this.postIdX,
      content: content ?? this.content,
      title: title ?? this.title,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      publishedAt: publishedAt ?? this.publishedAt,
      status: status ?? this.status,
      failureReason: failureReason ?? this.failureReason,
      visibility: visibility ?? this.visibility,
      cloudImageUrls: cloudImageUrls ?? this.cloudImageUrls,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      locationAddress: locationAddress ?? this.locationAddress,
    );
  }
}
