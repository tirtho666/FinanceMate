import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../models/transaction_model.dart';
import '../../models/transaction_summary_model.dart';

/// Local SQLite cache for the transaction feature.
///
/// It stores the last successful `GET /api/transactions` response so the list
/// and the overview render instantly (and fully offline), plus an offline queue
/// of transactions that still have to reach the backend (`pending_sync = 1`).
class TransactionLocalSource {
  static const String _fileName = 'financemate_cache.db';
  static const String _transactionsTable = 'transactions';
  static const String _summariesTable = 'summaries';

  Database? _database;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Fires after every local mutation so watchers can re-read the cache.
  Stream<void> get changes => _changes.stream;

  Future<void> init() async {
    if (_database != null) return;
    final directory = await getDatabasesPath();
    _database = await openDatabase(
      p.join(directory, _fileName),
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE $_transactionsTable ('
          'id TEXT PRIMARY KEY, '
          'user_id TEXT NOT NULL, '
          'type TEXT NOT NULL, '
          'amount REAL NOT NULL, '
          'category TEXT NOT NULL, '
          'date INTEGER NOT NULL, '
          'note TEXT, '
          'pending_sync INTEGER NOT NULL DEFAULT 0)',
        );
        await db.execute(
          'CREATE TABLE $_summariesTable ('
          'user_id TEXT PRIMARY KEY, '
          'balance REAL NOT NULL, '
          'total_income REAL NOT NULL, '
          'total_expense REAL NOT NULL, '
          'updated_at INTEGER NOT NULL)',
        );
      },
    );
  }

  Future<List<TransactionModel>> readTransactions(String userId) async {
    final db = await _requireDatabase();
    final rows = await db.query(
      _transactionsTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return rows.map(TransactionModel.fromMap).toList(growable: false);
  }

  /// The transactions still waiting to be pushed to the backend, oldest first so
  /// the queue is replayed in the order it was created.
  Future<List<TransactionModel>> readPending(String userId) async {
    final db = await _requireDatabase();
    final rows = await db.query(
      _transactionsTable,
      where: 'user_id = ? AND pending_sync = 1',
      whereArgs: [userId],
      orderBy: 'date ASC',
    );
    return rows.map(TransactionModel.fromMap).toList(growable: false);
  }

  Future<bool> isPending(String id) async {
    final db = await _requireDatabase();
    final rows = await db.query(
      _transactionsTable,
      columns: const ['pending_sync'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    return (rows.first['pending_sync'] as int? ?? 0) == 1;
  }

  /// Caches a batch coming from the backend. Queued rows are never touched;
  /// when [pruneMissing] is set (an unfiltered fetch) cached server rows that are
  /// no longer returned are dropped so deletions propagate.
  Future<void> replaceRemoteTransactions(
    String userId,
    List<TransactionModel> remote, {
    bool pruneMissing = true,
  }) async {
    final db = await _requireDatabase();
    await db.transaction((txn) async {
      if (pruneMissing) {
        await txn.delete(
          _transactionsTable,
          where: 'user_id = ? AND pending_sync = 0',
          whereArgs: [userId],
        );
      }
      for (final item in remote) {
        await txn.insert(
          _transactionsTable,
          item.toMap(pendingSync: false),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    _notify();
  }

  Future<void> insertTransaction(
    TransactionModel model, {
    required bool pendingSync,
  }) async {
    final db = await _requireDatabase();
    await db.insert(
      _transactionsTable,
      model.toMap(pendingSync: pendingSync),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notify();
  }

  /// Swaps a queued row for the one the backend stored; the server id may
  /// differ from the temporary local id.
  Future<void> markSynced(String localId, TransactionModel remote) async {
    final db = await _requireDatabase();
    await db.transaction((txn) async {
      await txn.delete(
        _transactionsTable,
        where: 'id = ?',
        whereArgs: [localId],
      );
      await txn.insert(
        _transactionsTable,
        remote.toMap(pendingSync: false),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    _notify();
  }

  Future<void> deleteTransaction(String id) async {
    final db = await _requireDatabase();
    await db.delete(_transactionsTable, where: 'id = ?', whereArgs: [id]);
    _notify();
  }

  Future<void> saveSummary(
    String userId,
    TransactionSummaryModel summary,
  ) async {
    final db = await _requireDatabase();
    await db.insert(
      _summariesTable,
      summary.toMap(userId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notify();
  }

  Future<TransactionSummaryModel?> readSummary(String userId) async {
    final db = await _requireDatabase();
    final rows = await db.query(
      _summariesTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TransactionSummaryModel.fromMap(rows.first);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
    if (!_changes.isClosed) await _changes.close();
  }

  Future<Database> _requireDatabase() async {
    await init();
    return _database!;
  }

  void _notify() {
    if (_changes.isClosed) return;
    _changes.add(null);
  }
}
