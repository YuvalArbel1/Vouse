import 'package:vouse_flutter/domain/entities/user_entity.dart';

/// A data model for local database storage, plus to/fromMap for SQLite.
class UserModel extends UserEntity {
  UserModel({
    required super.userId,
    required super.fullName,
    required super.dateOfBirth,
    required super.gender,
    super.xCredential,
  });

  /// Convert from a map (as stored in SQLite) to a `UserModel`.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] as String,
      fullName: map['fullName'] as String,
      // We'll parse dateOfBirth from string or int
      dateOfBirth: DateTime.parse(map['dateOfBirth'] as String),
      gender: map['gender'] as String,
      xCredential: map['xCredential'] as String?,
    );
  }

  /// Convert `UserModel` to a map for SQLite storage.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'xCredential': xCredential,
    };
  }
}
