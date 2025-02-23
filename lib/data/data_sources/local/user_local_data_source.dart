// lib/data/data_sources/local/user_local_data_source.dart

import 'package:sqflite/sqflite.dart';
import 'package:vouse_flutter/data/models/local_db/user_model.dart';

/// Handles CRUD operations on the 'user' table in the local SQLite database.
class UserLocalDataSource {
  final Database db;
  static const _tableName = 'user';

  /// Accepts a pre-initialized [Database] to interact with the 'user' table.
  UserLocalDataSource(this.db);

  /// Inserts or updates the given [user] using [ConflictAlgorithm.replace].
  Future<void> insertOrUpdateUser(UserModel user) async {
    await db.insert(
      _tableName,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves a [UserModel] by [userId], returning `null` if not found.
  Future<UserModel?> getUserById(String userId) async {
    final maps = await db.query(
      _tableName,
      where: 'userId = ?',
      whereArgs: [userId],
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }
}
