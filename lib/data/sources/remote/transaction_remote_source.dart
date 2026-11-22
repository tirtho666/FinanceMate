import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/entities/finance_transaction.dart';
import '../../../domain/failures/data_failure.dart';
import '../../models/transaction_model.dart';
import '../../models/transaction_summary_model.dart';

/// Transaction data source backed by the FinanceMate Node.js + PostgreSQL API.
///
/// [ApiClient] attaches the persisted `Authorization: Bearer <token>` header, so
/// every endpoint resolves to the signed-in user without the caller passing an
/// id. Network, DNS and timeout failures surface as a [DataFailure] with a
/// `null` status code, which is how the repository detects that a write has to
/// be queued offline.
class TransactionRemoteSource {
  TransactionRemoteSource(this._api);

  static const String _transactionsPath = '/api/transactions';
  static const String _summaryPath = '/api/transactions/summary';

  final ApiClient _api;

  /// `GET /api/transactions`, optionally narrowed by the UI filters.
  Future<List<TransactionModel>> fetchTransactions({
    DateTime? from,
    DateTime? to,
    String? category,
  }) async {
    try {
      final response = await _api.get(
        _transactionsPath,
        query: <String, dynamic>{
          'from': ?_isoDay(from),
          'to': ?_isoDay(to),
          'category': ?_trimmed(category),
        },
      );
      return _extractTransactions(response);
    } on ApiException catch (error) {
      throw DataFailure(error.message, statusCode: error.statusCode);
    }
  }

  /// `GET /api/transactions/summary`.
  Future<TransactionSummaryModel> fetchSummary() async {
    try {
      final response = await _api.get(_summaryPath);
      return TransactionSummaryModel.fromJson(
        _unwrapMap(response, const [
          'summary',
          'data',
          'result',
          'overview',
          'totals',
        ]),
      );
    } on ApiException catch (error) {
      throw DataFailure(error.message, statusCode: error.statusCode);
    }
  }

  /// `POST /api/transactions`.
  Future<TransactionModel> createTransaction({
    required TransactionType type,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    final payload = _body(
      type: type,
      amount: amount,
      category: category,
      date: date,
      note: note,
    );
    try {
      final response = await _api.post(_transactionsPath, body: payload);
      return _parseTransaction(response, payload);
    } on ApiException catch (error) {
      throw DataFailure(error.message, statusCode: error.statusCode);
    }
  }

  /// `PUT /api/transactions/:id`.
  Future<TransactionModel> updateTransaction({
    required String id,
    required TransactionType type,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    final payload = _body(
      type: type,
      amount: amount,
      category: category,
      date: date,
      note: note,
    );
    try {
      final response = await _api.put('$_transactionsPath/$id', body: payload);
      return _parseTransaction(response, payload, fallbackId: id);
    } on ApiException catch (error) {
      throw DataFailure(error.message, statusCode: error.statusCode);
    }
  }

  /// `DELETE /api/transactions/:id`.
  Future<void> deleteTransaction(String id) async {
    try {
      await _api.delete('$_transactionsPath/$id');
    } on ApiException catch (error) {
      throw DataFailure(error.message, statusCode: error.statusCode);
    }
  }

  Map<String, dynamic> _body({
    required TransactionType type,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) {
    return <String, dynamic>{
      'type': type.name,
      'amount': amount,
      'category': category,
      'date': date.toUtc().toIso8601String(),
      'note': note,
    };
  }

  /// The response body wins wherever it carries a field; otherwise the values
  /// the request sent are used, so a terse `{id: 7}` reply still yields a full
  /// model that can be cached locally.
  TransactionModel _parseTransaction(
    Map<String, dynamic> response,
    Map<String, dynamic> payload, {
    String? fallbackId,
  }) {
    final json = _unwrapMap(response, const [
      'transaction',
      'data',
      'result',
      'item',
    ]);
    final merged = <String, dynamic>{
      'id': ?fallbackId,
      ...payload,
      ...json,
    };
    return TransactionModel.fromJson(merged);
  }

  List<TransactionModel> _extractTransactions(Map<String, dynamic> response) {
    final items = <TransactionModel>[];
    for (final entry in _extractList(response)) {
      if (entry is Map) {
        items.add(TransactionModel.fromJson(Map<String, dynamic>.from(entry)));
      }
    }
    return List<TransactionModel>.unmodifiable(items);
  }

  List<Object?> _extractList(Map<String, dynamic> response) {
    const containerKeys = [
      'transactions',
      'items',
      'results',
      'list',
      'rows',
      'data',
    ];
    for (final key in containerKeys) {
      final value = response[key];
      if (value is List) return value;
      if (value is Map) {
        for (final inner in containerKeys) {
          final nested = value[inner];
          if (nested is List) return nested;
        }
      }
    }
    return const [];
  }

  Map<String, dynamic> _unwrapMap(
    Map<String, dynamic> response,
    List<String> keys,
  ) {
    for (final key in keys) {
      final nested = response[key];
      if (nested is Map) return Map<String, dynamic>.from(nested);
    }
    return response;
  }

  String? _trimmed(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  String? _isoDay(DateTime? value) {
    if (value == null) return null;
    return DateTime(value.year, value.month, value.day).toIso8601String();
  }
}
