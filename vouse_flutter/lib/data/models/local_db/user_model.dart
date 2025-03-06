// lib/data/models/local_db/user_model.dart

import '../../../domain/entities/local_db/user_entity.dart';

/// Extends [UserEntity] to handle serialization for the local SQLite database.
///
/// Includes factory methods to convert to/from a [Map].
class UserModel extends UserEntity {
  UserModel({
    required super.userId,
    required super.fullName,
    required super.dateOfBirth,
    required super.gender,
    super.avatarPath,
  });

  /// Reconstructs a [UserModel] from a database [map].
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] as String,
      fullName: map['fullName'] as String,
      dateOfBirth: DateTime.parse(map['dateOfBirth'] as String),
      gender: map['gender'] as String,
      avatarPath: map['avatarPath'] as String?,
    );
  }

  /// Converts this [UserModel] into a map for database insertion.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'avatarPath': avatarPath,
    };
  }
}
