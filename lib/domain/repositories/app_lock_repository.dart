/// Local (on-device) App Lock, independent from the account session.
abstract class AppLockRepository {
  /// Whether an App Lock password hash is stored on this device.
  bool get isEnabled;

  /// Loads the stored hash into RAM so verification never touches the network.
  Future<void> load();

  /// Hashes [password] (synchronously, SHA-256) and persists the hash.
  Future<void> setPassword(String password);

  /// Compares [password] against the in-memory hash.
  Future<bool> verifyPassword(String password);

  /// Removes the App Lock password from this device.
  Future<void> clear();
}
