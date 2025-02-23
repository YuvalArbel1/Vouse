// lib/data/clients/local_db/local_database_manager.dart

import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Opens and initializes the SQLite database.
///
/// This class handles tasks like creating tables and ensuring foreign keys
/// are enabled, but does not perform actual CRUD operations. Those should
/// be defined in separate data sources (e.g., `UserLocalDataSource`, `PostLocalDataSource`).
class LocalDatabaseManager {
  static const _dbName = 'vouse_app.db';
  static const _dbVersion = 1;
  static Database? _database;

  /// Returns a shared [Database] instance, creating it if necessary.
  static Future<Database> getDatabase() async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Creates or opens the app's local database.
  static Future<Database> _initDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, _dbName);

    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Creates the [user] and [posts] tables at DB creation time.
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user (
        userId TEXT PRIMARY KEY,
        fullName TEXT NOT NULL,
        dateOfBirth TEXT NOT NULL,
        gender TEXT NOT NULL,
        avatarPath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE posts (
        postIdLocal TEXT PRIMARY KEY,
        postIdX TEXT,
        userId TEXT NOT NULL,
        content TEXT NOT NULL,
        title TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        scheduledAt TEXT,
        visibility TEXT,
        localImagePaths TEXT,
        cloudImageUrls TEXT,
        locationLat REAL,
        locationLng REAL,
        locationAddress TEXT,
        FOREIGN KEY(userId) REFERENCES user(userId)
      )
    ''');
  }
}
