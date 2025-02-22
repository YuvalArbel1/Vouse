import 'package:sqflite/sqflite.dart';
import 'package:vouse_flutter/data/models/local_db/post_model.dart';

import '../../clients/local_db/local_database.dart';

class PostLocalDataSource {
  final UserLocalDataSource _dbProvider; // Reuse same DB instance

  PostLocalDataSource(this._dbProvider);

  Future<Database> get _db async => _dbProvider.database;

  Future<void> insertOrUpdatePost(PostModel post) async {
    final db = await _db;
    await db.insert(
      'posts',
      post.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<PostModel?> getPostById(String postIdLocal) async {
    final db = await _db;
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

  Future<List<PostModel>> getPostsByUser(String userId) async {
    final db = await _db;
    final maps = await db.query(
      'posts',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => PostModel.fromMap(m)).toList();
  }

  Future<void> deletePost(String postIdLocal) async {
    final db = await _db;
    await db.delete(
      'posts',
      where: 'postIdLocal = ?',
      whereArgs: [postIdLocal],
    );
  }
}
