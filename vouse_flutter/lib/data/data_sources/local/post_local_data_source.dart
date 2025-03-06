// lib/data/data_sources/local/post_local_data_source.dart

import 'package:sqflite/sqflite.dart';
import 'package:vouse_flutter/data/models/local_db/post_model.dart';

/// Provides CRUD operations on the 'posts' table in the local SQLite database.
class PostLocalDataSource {
  final Database db;

  /// Expects an initialized [Database] to interact with the 'posts' table.
  PostLocalDataSource(this.db);

  /// Inserts or updates a [post] in the 'posts' table.
  ///
  /// Uses [ConflictAlgorithm.replace] to overwrite any existing row with the same primary key.
  Future<void> insertOrUpdatePost(PostModel post) async {
    await db.insert(
      'posts',
      post.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves a post by its [postIdLocal], or returns `null` if not found.
  Future<PostModel?> getPostById(String postIdLocal) async {
    final maps = await db.query(
      'posts',
      where: 'postIdLocal = ?',
      whereArgs: [postIdLocal],
    );
    if (maps.isNotEmpty) {
      return PostModel.fromMap(maps.first);
    }
    return null;
  }

  /// Returns a list of posts belonging to [userId], ordered by [createdAt] descending.
  Future<List<PostModel>> getPostsByUser(String userId) async {
    final maps = await db.query(
      'posts',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => PostModel.fromMap(m)).toList();
  }

  /// Deletes a post by its [postIdLocal].
  Future<void> deletePost(String postIdLocal) async {
    await db.delete(
      'posts',
      where: 'postIdLocal = ?',
      whereArgs: [postIdLocal],
    );
  }
}
