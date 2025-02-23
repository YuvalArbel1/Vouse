// lib/presentation/providers/local_db/database_provider.dart

import 'package:riverpod/riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../data/clients/local_db/local_database.dart';

/// Provides a [Database] instance via [LocalDatabaseManager].
///
/// Any data source or repository that needs the DB can watch this provider.
final localDatabaseProvider = FutureProvider<Database>((ref) async {
  return LocalDatabaseManager.getDatabase();
});
