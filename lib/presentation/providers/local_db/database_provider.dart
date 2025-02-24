// lib/presentation/providers/local_db/database_provider.dart

import 'package:riverpod/riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../data/clients/local_db/local_database.dart';

/// Exposes a [FutureProvider<Database>] that initializes and provides
/// a shared SQLite [Database] via [LocalDatabaseManager].
///
/// Data sources and repositories can watch or read this provider to
/// obtain the database instance once it's ready.
final localDatabaseProvider = FutureProvider<Database>((ref) async {
  return LocalDatabaseManager.getDatabase();
});
