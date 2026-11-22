import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Talks to the platform keystore to persist the auth session (JWT + user
/// details) and the App Lock hash.
///
/// Every value is cached in RAM after [restore] so the rest of the app can read
/// the session synchronously and verify the App Lock hash locally without
/// touching the keystore or the network.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'auth.jwt_token';
  static const String _userIdKey = 'auth.user_id';
  static const String _emailKey = 'auth.user_email';
  static const String _displayNameKey = 'auth.user_display_name';
  static const String _appLockHashKey = 'security.app_lock_hash';

  final FlutterSecureStorage _storage;

  bool _isRestored = false;
  String? _token;
  String? _userId;
  String? _email;
  String? _displayName;
  String? _appLockHash;

  bool get isRestored => _isRestored;

  /// Bearer token of the persisted session, or `null` when signed out.
  String? get token => _token;

  String? get userId => _userId;

  String? get email => _email;

  String? get displayName => _displayName;

  /// SHA-256 hash of the App Lock password, or `null` when not configured.
  String? get appLockHash => _appLockHash;

  bool get hasSession => (_token ?? '').isNotEmpty;

  /// Loads every persisted value into RAM. Safe to call more than once.
  Future<void> restore() async {
    if (_isRestored) return;
    _token = await _storage.read(key: _tokenKey);
    _userId = await _storage.read(key: _userIdKey);
    _email = await _storage.read(key: _emailKey);
    _displayName = await _storage.read(key: _displayNameKey);
    _appLockHash = await _storage.read(key: _appLockHashKey);
    _isRestored = true;
  }

  Future<void> saveSession({
    required String token,
    required String userId,
    String? email,
    String? displayName,
  }) async {
    await Future.wait<void>([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _emailKey, value: email),
      _storage.write(key: _displayNameKey, value: displayName),
    ]);
    _token = token;
    _userId = userId;
    _email = email;
    _displayName = displayName;
    _isRestored = true;
  }

  Future<void> updateSessionUser({String? email, String? displayName}) async {
    if (email != null) {
      await _storage.write(key: _emailKey, value: email);
      _email = email;
    }
    if (displayName != null) {
      await _storage.write(key: _displayNameKey, value: displayName);
      _displayName = displayName;
    }
  }

  /// Drops the JWT and the cached user details. The App Lock hash is kept so the
  /// device stays protected until the App Lock is explicitly turned off.
  Future<void> clearSession() async {
    await Future.wait<void>([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _emailKey),
      _storage.delete(key: _displayNameKey),
    ]);
    _token = null;
    _userId = null;
    _email = null;
    _displayName = null;
  }

  Future<void> saveAppLockHash(String hash) async {
    await _storage.write(key: _appLockHashKey, value: hash);
    _appLockHash = hash;
    _isRestored = true;
  }

  Future<void> clearAppLockHash() async {
    await _storage.delete(key: _appLockHashKey);
    _appLockHash = null;
  }
}
