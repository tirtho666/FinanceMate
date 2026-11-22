class DataFailure implements Exception {
  const DataFailure(this.message, {this.statusCode});

  final String message;

  /// HTTP status code when the backend answered, or `null` for network, DNS and
  /// timeout failures. The transaction feature uses this to decide whether a
  /// write has to be queued offline and replayed later.
  final int? statusCode;

  /// True when the request never reached the backend (offline, timeout, …).
  bool get isOffline => statusCode == null;

  @override
  String toString() => message;
}
