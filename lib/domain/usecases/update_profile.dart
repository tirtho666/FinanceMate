import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

class UpdateProfile {
  const UpdateProfile(this._authRepository, this._userRepository);

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  Future<void> call({
    String? fullName,
    String? phoneNumber,
    String? email,
  }) async {
    final normalizedFullName = fullName?.trim();
    final normalizedEmail = email?.trim();
    final normalizedPhone = phoneNumber?.trim();

    if (normalizedFullName != null && normalizedFullName.isNotEmpty) {
      await _authRepository.updateDisplayName(normalizedFullName);
    }
    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      await _authRepository.updateEmail(normalizedEmail);
    }
    await _authRepository.reloadUser();
    await _userRepository.updateProfile(
      fullName: normalizedFullName,
      phoneNumber: normalizedPhone,
    );
  }
}
