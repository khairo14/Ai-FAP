import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Singleton SQLite database used for offline caching and sync queue.
///
/// Tables:
///   expenses        — cached expense rows (JSON payload)
///   income_records  — cached income rows
///   budgets         — cached budget rows
///   accounts        — cached account rows
///   categories      — cached category rows
///   pending_ops     — operations queued while offline
class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  Database? _db;

  Future<Database?> get database async {
    if (kIsWeb) return null;
    _db ??= await _open();
    return _db!;
  }

  // ---------------------------------------------------------------------------
  // Schema
  // ---------------------------------------------------------------------------

  static const int _version = 5;

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'fundvanceai_cache.db');

    return openDatabase(
      path,
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS expenses (
            id        TEXT PRIMARY KEY,
            user_id   TEXT NOT NULL,
            payload   TEXT NOT NULL,
            synced_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS income_records (
            id        TEXT PRIMARY KEY,
            user_id   TEXT NOT NULL,
            payload   TEXT NOT NULL,
            synced_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS budgets (
            id        TEXT PRIMARY KEY,
            user_id   TEXT NOT NULL,
            payload   TEXT NOT NULL,
            synced_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS accounts (
            id        TEXT PRIMARY KEY,
            user_id   TEXT NOT NULL,
            payload   TEXT NOT NULL,
            synced_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS categories (
            id        TEXT PRIMARY KEY,
            user_id   TEXT NOT NULL,
            payload   TEXT NOT NULL,
            synced_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS transfers (
            id        TEXT PRIMARY KEY,
            user_id   TEXT NOT NULL,
            payload   TEXT NOT NULL,
            synced_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS pending_ops (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            operation   TEXT NOT NULL,
            table_name  TEXT NOT NULL,
            record_id   TEXT NOT NULL,
            payload     TEXT NOT NULL,
            created_at  INTEGER NOT NULL,
            attempts    INTEGER NOT NULL DEFAULT 0
          )
        ''');

        // Indexes for common lookup
        await db.execute('CREATE INDEX idx_exp_user  ON expenses(user_id)');
        await db
            .execute('CREATE INDEX idx_inc_user  ON income_records(user_id)');
        await db.execute('CREATE INDEX idx_bud_user  ON budgets(user_id)');
        await db.execute('CREATE INDEX idx_acc_user  ON accounts(user_id)');
        await db.execute('CREATE INDEX idx_cat_user  ON categories(user_id)');
        await db.execute('CREATE INDEX idx_tfr_user  ON transfers(user_id)');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS income_categories (
            id        TEXT PRIMARY KEY,
            user_id   TEXT NOT NULL,
            payload   TEXT NOT NULL,
            synced_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_icat_user ON income_categories(user_id)');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS transfer_categories_cache (
            id        TEXT PRIMARY KEY,
            user_id   TEXT NOT NULL,
            payload   TEXT NOT NULL,
            synced_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_tcat_user ON transfer_categories_cache(user_id)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS accounts (
              id        TEXT PRIMARY KEY,
              user_id   TEXT NOT NULL,
              payload   TEXT NOT NULL,
              synced_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS categories (
              id        TEXT PRIMARY KEY,
              user_id   TEXT NOT NULL,
              payload   TEXT NOT NULL,
              synced_at INTEGER NOT NULL
            )
          ''');
          await db.execute('CREATE INDEX idx_acc_user  ON accounts(user_id)');
          await db.execute('CREATE INDEX idx_cat_user  ON categories(user_id)');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS transfers (
              id        TEXT PRIMARY KEY,
              user_id   TEXT NOT NULL,
              payload   TEXT NOT NULL,
              synced_at INTEGER NOT NULL
            )
          ''');
          await db.execute('CREATE INDEX idx_tfr_user  ON transfers(user_id)');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS income_categories (
              id        TEXT PRIMARY KEY,
              user_id   TEXT NOT NULL,
              payload   TEXT NOT NULL,
              synced_at INTEGER NOT NULL
            )
          ''');
          await db.execute(
              'CREATE INDEX idx_icat_user ON income_categories(user_id)');
        }
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS transfer_categories_cache (
              id        TEXT PRIMARY KEY,
              user_id   TEXT NOT NULL,
              payload   TEXT NOT NULL,
              synced_at INTEGER NOT NULL
            )
          ''');
          await db.execute(
              'CREATE INDEX idx_tcat_user ON transfer_categories_cache(user_id)');
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Generic cache helpers
  // ---------------------------------------------------------------------------

  Future<void> upsertRow({
    required String table,
    required String id,
    required String userId,
    required Map<String, dynamic> payload,
  }) async {
    final db = await database;
    if (db == null) return;
    await db.insert(
      table,
      {
        'id': id,
        'user_id': userId,
        'payload': jsonEncode(payload),
        'synced_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertRows({
    required String table,
    required String userId,
    required List<Map<String, dynamic>> rows,
    required String Function(Map<String, dynamic>) idGetter,
  }) async {
    final db = await database;
    if (db == null) return;
    final batch = db.batch();
    for (final row in rows) {
      batch.insert(
        table,
        {
          'id': idGetter(row),
          'user_id': userId,
          'payload': jsonEncode(row),
          'synced_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getRows({
    required String table,
    required String userId,
  }) async {
    final db = await database;
    if (db == null) return [];
    final rows = await db.query(
      table,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'synced_at DESC',
    );
    return rows
        .map((r) => jsonDecode(r['payload'] as String) as Map<String, dynamic>)
        .toList();
  }

  Future<Map<String, dynamic>?> getRow({
    required String table,
    required String id,
    required String userId,
  }) async {
    final db = await database;
    if (db == null) return null;
    final rows = await db.query(
      table,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['payload'] as String) as Map<String, dynamic>;
  }

  Future<void> deleteRow({
    required String table,
    required String id,
    required String userId,
  }) async {
    final db = await database;
    if (db == null) return;
    await db.delete(
      table,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> clearUserRows({
    required String table,
    required String userId,
  }) async {
    final db = await database;
    if (db == null) return;
    await db.delete(table, where: 'user_id = ?', whereArgs: [userId]);
  }

  // ---------------------------------------------------------------------------
  // Sync queue
  // ---------------------------------------------------------------------------

  Future<void> enqueuePendingOp({
    required String operation, // 'INSERT' | 'UPDATE' | 'DELETE'
    required String tableName, // remote Supabase table name
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    final db = await database;
    if (db == null) return;
    await db.insert('pending_ops', {
      'operation': operation,
      'table_name': tableName,
      'record_id': recordId,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'attempts': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingOps() async {
    final db = await database;
    if (db == null) return [];
    return db.query('pending_ops', orderBy: 'created_at ASC');
  }

  Future<void> deletePendingOp(int id) async {
    final db = await database;
    if (db == null) return;
    await db.delete('pending_ops', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementAttempts(int id) async {
    final db = await database;
    if (db == null) return;
    await db.rawUpdate(
      'UPDATE pending_ops SET attempts = attempts + 1 WHERE id = ?',
      [id],
    );
  }

  Future<int> pendingOpsCount() async {
    final db = await database;
    if (db == null) return 0;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM pending_ops');
    return (result.first['count'] as int?) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  Future<void> close() async {
    if (kIsWeb) return;
    await _db?.close();
    _db = null;
  }
}
