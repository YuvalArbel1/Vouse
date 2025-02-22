import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../models/local_db/user_model.dart';

/// Responsible for opening the local DB and performing CRUD on the "users" table.
class UserLocalDataSource {
  static const _dbName = 'vouse_app.db';
  static const _dbVersion = 1;
  static const _tableName = 'user';

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, _dbName);

    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE user (
      userId TEXT PRIMARY KEY,
      fullName TEXT NOT NULL,
      dateOfBirth TEXT NOT NULL,
      gender TEXT NOT NULL,
      avatarPath TEXT
    )
  ''');

    // The "posts" table references "user(userId)" as a foreign key.
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

  /// Insert or replace a user in "users" table
  Future<void> insertOrUpdateUser(UserModel user) async {
    final db = await database;
    await db.insert(
      _tableName,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a user by userId
  Future<UserModel?> getUserById(String userId) async {
    final db = await database;
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
