import '../repositories/user_repository.dart';

class UpdateCurrency {
  const UpdateCurrency(this._repository);

  final UserRepository _repository;

  Future<void> call(String currency) {
    final normalized = currency.trim().toUpperCase();
    return _repository.updateCurrency(normalized);
  }
}
