import '../repositories/app_lock_repository.dart';

class SetAppLockPassword {
  const SetAppLockPassword(this._repository);

  final AppLockRepository _repository;

  Future<void> call(String password) => _repository.setPassword(password);
}
