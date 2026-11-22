/// Raised by [ApiClient] for every non-2xx response, timeout, or socket error.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  /// Human readable, UI-ready message (already parsed from the response body
  /// when the backend sent one).
  final String message;

  final int? statusCode;

  /// True when the backend has no such route (or does not allow the verb),
  /// which lets callers fall back to an alternative endpoint.
  bool get isMissingEndpoint => statusCode == 404 || statusCode == 405;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}
