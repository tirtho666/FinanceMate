import '../repositories/app_lock_repository.dart';

class VerifyAppLockPassword {
  const VerifyAppLockPassword(this._repository);

  final AppLockRepository _repository;

  Future<bool> call(String password) => _repository.verifyPassword(password);
}
