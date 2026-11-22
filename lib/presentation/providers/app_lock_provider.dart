import 'package:flutter/foundation.dart';

import '../../domain/repositories/app_lock_repository.dart';
import '../../domain/usecases/set_app_lock_password.dart';
import '../../domain/usecases/verify_app_lock_password.dart';

/// Presentation state for the dual-security App Lock.
class AppLockProvider extends ChangeNotifier {
  AppLockProvider({
    required this.setPasswordUseCase,
    required this.verifyPasswordUseCase,
    required this.repository,
  });

  final SetAppLockPassword setPasswordUseCase;
  final VerifyAppLockPassword verifyPasswordUseCase;
  final AppLockRepository repository;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isEnabled => repository.isEnabled;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;

  /// Pulls the stored hash from secure storage into RAM (called while the app
  /// boots, before any navigation happens).
  Future<void> load() async {
    await repository.load();
    notifyListeners();
  }

  /// Hashes [password] synchronously and stores the hash on device.
  Future<void> setPassword(String password) async {
    await setPasswordUseCase(password);
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> unlock(String password) async {
    if (_isLoading) return false;
    _errorMessage = null;
    _setLoading(true);
    try {
      final verified = await verifyPasswordUseCase(password);
      if (!verified) {
        _errorMessage = 'Incorrect password. Please try again.';
      }
      return verified;
    } catch (_) {
      _errorMessage = 'Could not verify your password. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> disable() async {
    await repository.clear();
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
