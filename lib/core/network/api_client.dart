import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/secure_storage_service.dart';
import 'api_exception.dart';

/// Thin JSON REST client for the FinanceMate Node.js + PostgreSQL backend.
///
/// * every request carries JSON headers and a 30 second timeout (Render's free
///   tier can take a while to wake up from a cold start);
/// * the persisted JWT is attached automatically as `Authorization: Bearer …`;
/// * non-2xx responses are converted into an [ApiException] with a clean,
///   UI-ready message parsed from the response body.
class ApiClient {
  ApiClient(
    this._storage, {
    http.Client? httpClient,
    String? baseUrl,
  })  : _http = httpClient ?? http.Client(),
        _baseUrl = _normalizeBaseUrl(baseUrl ?? defaultBaseUrl);

  static const String defaultBaseUrl = 'https://financemate-backend.onrender.com';

  /// Render free instances sleep when idle, so allow a long cold start.
  static const Duration requestTimeout = Duration(seconds: 30);

  final SecureStorageService _storage;
  final http.Client _http;
  final String _baseUrl;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool attachToken = true,
  }) {
    return _send(
      () => _http.get(_uri(path, query), headers: _headers(attachToken)),
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    bool attachToken = true,
  }) {
    return _send(
      () => _http.post(
        _uri(path),
        headers: _headers(attachToken),
        body: _encode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Object? body,
    bool attachToken = true,
  }) {
    return _send(
      () => _http.put(
        _uri(path),
        headers: _headers(attachToken),
        body: _encode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Object? body,
    bool attachToken = true,
  }) {
    return _send(
      () => _http.patch(
        _uri(path),
        headers: _headers(attachToken),
        body: _encode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Object? body,
    bool attachToken = true,
  }) {
    return _send(
      () => _http.delete(
        _uri(path),
        headers: _headers(attachToken),
        body: _encode(body),
      ),
    );
  }

  void close() => _http.close();

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_baseUrl$normalized');
    if (query == null || query.isEmpty) return uri;
    final params = <String, String>{
      for (final entry in query.entries)
        if (entry.value != null) entry.key: '${entry.value}',
    };
    return uri.replace(queryParameters: params);
  }

  Map<String, String> _headers(bool attachToken) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = _storage.token;
    if (attachToken && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String? _encode(Object? body) => body == null ? null : jsonEncode(body);

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(requestTimeout);
      return _parse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        error.message.isEmpty
            ? 'Network error. Check your connection and try again.'
            : error.message,
      );
    } on FormatException {
      throw const ApiException('The server sent an unexpected response.');
    } catch (_) {
      throw const ApiException(
        'Could not reach the server. Check your connection and try again.',
      );
    }
  }

  Map<String, dynamic> _parse(http.Response response) {
    final decoded = _tryDecode(response.body);
    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    if (isSuccess) {
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded == null) return const <String, dynamic>{};
      return <String, dynamic>{'data': decoded};
    }
    throw ApiException(
      _messageFor(response.statusCode, decoded),
      statusCode: response.statusCode,
    );
  }

  Object? _tryDecode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  String _messageFor(int statusCode, Object? decoded) {
    final serverMessage =
        _firstMessage(decoded) ?? _fallbackMessageFor(statusCode);
    return serverMessage;
  }

  /// Pulls the first human readable string out of the many shapes a Node
  /// backend may use: `{message: …}`, `{error: "…"}`, `{errors: [...]}`,
  /// `{error: {message: …}}`, or a bare string body.
  String? _firstMessage(Object? decoded) {
    if (decoded is String) {
      final trimmed = decoded.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (decoded is List) {
      for (final item in decoded) {
        final message = _firstMessage(item);
        if (message != null) return message;
      }
      return null;
    }
    if (decoded is Map) {
      for (final key in const ['message', 'error', 'detail', 'msg', 'errors']) {
        final message = _firstMessage(decoded[key]);
        if (message != null) return message;
      }
    }
    return null;
  }

  String _fallbackMessageFor(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your details.';
      case 401:
        return 'Your session is not valid. Please sign in again.';
      case 403:
        return 'You are not allowed to perform this action.';
      case 404:
        return 'The requested service is unavailable right now.';
      case 405:
        return 'This action is not available on the server yet.';
      case 409:
        return 'An account already exists for that email.';
      case 422:
        return 'Please check the details you entered.';
      case 429:
        return 'Too many attempts. Please try again later.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'The server is unavailable right now. Please try again.';
      default:
        return 'Request failed ($statusCode). Please try again.';
    }
  }

  static String _normalizeBaseUrl(String baseUrl) {
    final trimmed = baseUrl.trim();
    final withoutTrailingSlash = trimmed.replaceFirst(RegExp(r'/+$'), '');
    return withoutTrailingSlash.isEmpty ? defaultBaseUrl : withoutTrailingSlash;
  }
}
