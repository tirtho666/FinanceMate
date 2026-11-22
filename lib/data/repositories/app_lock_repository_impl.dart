import '../../core/security/app_lock_hasher.dart';
import '../../domain/repositories/app_lock_repository.dart';
import '../sources/local/app_lock_local_source.dart';

class AppLockRepositoryImpl implements AppLockRepository {
  AppLockRepositoryImpl(this._localSource);

  final AppLockLocalSource _localSource;

  @override
  bool get isEnabled => _localSource.hasHash;

  @override
  Future<void> load() => _localSource.load();

  @override
  Future<void> setPassword(String password) =>
      _localSource.writeHash(AppLockHasher.hash(password));

  @override
  Future<bool> verifyPassword(String password) async {
    final storedHash = _localSource.hashInMemory;
    // No App Lock configured yet: nothing to verify against.
    if (storedHash == null || storedHash.isEmpty) return true;
    return AppLockHasher.matches(password: password, hashValue: storedHash);
  }

  @override
  Future<void> clear() => _localSource.deleteHash();
}
