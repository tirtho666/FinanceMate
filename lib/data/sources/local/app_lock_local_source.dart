import '../../../core/storage/secure_storage_service.dart';

/// Local cache for the App Lock hash.
///
/// The hash lives in `flutter_secure_storage` but is also mirrored in RAM so
/// [hasHash] and [hashInMemory] can be read synchronously while the app boots.
class AppLockLocalSource {
  AppLockLocalSource(this._storage);

  final SecureStorageService _storage;

  String? _hashInMemory;

  bool get hasHash => (_hashInMemory ?? '').isNotEmpty;

  String? get hashInMemory => _hashInMemory;

  /// Hydrates the in-memory hash from secure storage.
  Future<void> load() async {
    await _storage.restore();
    _hashInMemory = _storage.appLockHash;
  }

  Future<void> writeHash(String hash) async {
    await _storage.saveAppLockHash(hash);
    _hashInMemory = hash;
  }

  Future<void> deleteHash() async {
    await _storage.clearAppLockHash();
    _hashInMemory = null;
  }
}
