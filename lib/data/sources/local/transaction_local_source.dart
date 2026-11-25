import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../models/transaction_model.dart';
import '../../models/transaction_summary_model.dart';

/// Local SQLite cache for the transaction feature.
///
/// It stores the last successful `GET /api/transactions` response so the list
/// and the overview render instantly (and fully offline), plus two offline
/// queues that still have to reach the backend: transactions created offline
/// (`pending_sync = 1`) and transactions removed offline (`pending_delete = 1`).
///
/// Rows flagged `pending_delete = 1` are hidden from every read so a delete
/// shows up in the UI and the balance immediately, while the remote `DELETE`
/// is replayed the next time the device is online.
class TransactionLocalSource {
  static const String _fileName = 'financemate_cache.db';
  static const String _transactionsTable = 'transactions';
  static const String _summariesTable = 'summaries';

  /// Bumped to `2` to add the `pending_delete` column; [onUpgrade] migrates
  /// existing caches in place so no user data is lost.
  static const int _schemaVersion = 2;

  Database? _database;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Fires after every local mutation so watchers can re-read the cache.
  Stream<void> get changes => _changes.stream;

  Future<void> init() async {
    if (_database != null) return;
    final directory = await getDatabasesPath();
    _database = await openDatabase(
      p.join(directory, _fileName),
      version: _schemaVersion,
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
          'pending_sync INTEGER NOT NULL DEFAULT 0, '
          'pending_delete INTEGER NOT NULL DEFAULT 0)',
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
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1 -> v2: add the offline-delete flag without touching existing rows.
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $_transactionsTable '
            'ADD COLUMN pending_delete INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }

  /// The visible transactions of [userId], newest-added first.
  ///
  /// Ordering is strictly by insertion order — transaction `date` and `amount`
  /// are ignored:
  /// * rows created offline (`local-…` ids) sit at the very top, most recently
  ///   added first, and keep that position once they sync;
  /// * synced rows follow, ordered by their numeric server `id` descending (the
  ///   auto-increment primary key, so the highest id is the newest).
  ///
  /// Rows queued for remote deletion (`pending_delete = 1`) are filtered out so
  /// a delete disappears from the list the instant it is requested, even while
  /// still offline.
  Future<List<TransactionModel>> readTransactions(String userId) async {
    final db = await _requireDatabase();
    final rows = await db.query(
      _transactionsTable,
      where: 'user_id = ? AND pending_delete = 0',
      whereArgs: [userId],
    );
    final items = rows.map(TransactionModel.fromMap).toList();
    items.sort(_byNewestAdded);
    return List<TransactionModel>.unmodifiable(items);
  }

  /// The transactions still waiting to be pushed to the backend, replayed in
  /// exact creation order (oldest insert first). Because the server assigns its
  /// auto-increment `id` in this order, the newest-added-first list order is
  /// preserved once these queued rows sync. Ordering ignores `date`.
  Future<List<TransactionModel>> readPending(String userId) async {
    final db = await _requireDatabase();
    final rows = await db.query(
      _transactionsTable,
      where: 'user_id = ? AND pending_sync = 1 AND pending_delete = 0',
      whereArgs: [userId],
    );
    final items = rows.map(TransactionModel.fromMap).toList();
    items.sort(_byOldestAdded);
    return List<TransactionModel>.unmodifiable(items);
  }

  /// The transactions removed offline that still have to be deleted on the
  /// backend, oldest first so the queue is replayed in creation order.
  Future<List<TransactionModel>> readPendingDeletes(String userId) async {
    final db = await _requireDatabase();
    final rows = await db.query(
      _transactionsTable,
      where: 'user_id = ? AND pending_delete = 1',
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

  /// Flags the cached row with [id] as removed offline (`pending_delete = 1`).
  ///
  /// The row is kept so the queued `DELETE` can be replayed on reconnect, but it
  /// is hidden from every read — so it leaves the list and the balance at once.
  Future<void> markPendingDelete(String id) async {
    final db = await _requireDatabase();
    await db.update(
      _transactionsTable,
      <String, Object?>{'pending_delete': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    _notify();
  }

  /// Ids of the rows queued for remote deletion, read inside a transaction so a
  /// refresh can skip re-inserting a transaction the user already removed.
  Future<Set<String>> _pendingDeleteIds(
    DatabaseExecutor executor,
    String userId,
  ) async {
    final rows = await executor.query(
      _transactionsTable,
      columns: const ['id'],
      where: 'user_id = ? AND pending_delete = 1',
      whereArgs: [userId],
    );
    return rows.map((row) => row['id'] as String).toSet();
  }

  /// Caches a batch coming from the backend. Queued rows are never touched;
  /// when [pruneMissing] is set (an unfiltered fetch) cached server rows that are
  /// no longer returned are dropped so deletions propagate.
  ///
  /// Rows flagged `pending_delete = 1` are both protected from pruning and
  /// skipped while inserting, so a fetch can never resurrect a transaction the
  /// user deleted offline before its remote `DELETE` has been replayed.
  Future<void> replaceRemoteTransactions(
    String userId,
    List<TransactionModel> remote, {
    bool pruneMissing = true,
  }) async {
    final db = await _requireDatabase();
    await db.transaction((txn) async {
      final pendingDeleteIds = await _pendingDeleteIds(txn, userId);

      if (pruneMissing) {
        await txn.delete(
          _transactionsTable,
          where: 'user_id = ? AND pending_sync = 0 AND pending_delete = 0',
          whereArgs: [userId],
        );
      }
      for (final item in remote) {
        if (pendingDeleteIds.contains(item.id)) continue;
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

  /// Permanently removes the cached row with [id] from the `transactions` table.
  ///
  /// The offline sync queue shares this table (`pending_sync = 1`), so matching
  /// on the `id` column alone purges a synced row *and* any queued copy of the
  /// same transaction — a deleted row can therefore never be re-uploaded or
  /// restored on the next launch. The column has TEXT affinity, so SQLite
  /// matches the id whether it arrives as `'7'` or `7`.
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

  /// Compares two rows purely by insertion order, newest first. Locally created
  /// rows (`local-…`) always rank above synced ones so a just-added offline
  /// transaction is at index 0; within each group the highest key wins.
  static int _byNewestAdded(TransactionModel a, TransactionModel b) {
    final aLocal = _isLocalId(a.id);
    final bLocal = _isLocalId(b.id);
    if (aLocal != bLocal) return aLocal ? -1 : 1;

    if (aLocal) {
      final bySeq = _localSequence(b.id).compareTo(_localSequence(a.id));
      return bySeq != 0 ? bySeq : b.id.compareTo(a.id);
    }

    final aId = int.tryParse(a.id);
    final bId = int.tryParse(b.id);
    if (aId != null && bId != null) return bId.compareTo(aId);
    return b.id.compareTo(a.id);
  }

  /// Compares two queued rows by exact insertion order, oldest first, so the
  /// offline create queue replays in the order the rows were added.
  static int _byOldestAdded(TransactionModel a, TransactionModel b) {
    final bySeq = _localSequence(a.id).compareTo(_localSequence(b.id));
    return bySeq != 0 ? bySeq : a.id.compareTo(b.id);
  }

  static bool _isLocalId(String id) => id.startsWith('local-');

  /// The monotonic insertion key embedded in a locally queued id
  /// (`local-<micros>-<seed>`); a larger value means a more recent insert.
  static int _localSequence(String id) {
    final parts = id.split('-');
    if (parts.length >= 2) {
      final micros = int.tryParse(parts[1]);
      if (micros != null) return micros;
    }
    return 0;
  }

  void _notify() {
    if (_changes.isClosed) return;
    _changes.add(null);
  }
}
