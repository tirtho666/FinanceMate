import 'package:flutter/foundation.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/failures/data_failure.dart';
import '../../domain/repositories/app_lock_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/change_password.dart';
import '../../domain/usecases/update_currency.dart';
import '../../domain/usecases/update_profile.dart';

class UserProvider extends ChangeNotifier {
  UserProvider({
    required this.updateProfileUseCase,
    required this.changePasswordUseCase,
    required this.updateCurrencyUseCase,
    required this.authRepository,
    required this.appLockRepository,
    AppUser? initialUser,
  }) : _authUser = initialUser;

  final UpdateProfile updateProfileUseCase;
  final ChangePassword changePasswordUseCase;
  final UpdateCurrency updateCurrencyUseCase;
  final AuthRepository authRepository;
  final AppLockRepository appLockRepository;

  AppUser? _authUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  AppUser? get authUser => _authUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;
  bool get hasSuccess => _successMessage != null && _successMessage!.isNotEmpty;

  void bindAuthUser(AppUser? user) {
    if (_authUser == user) return;
    _authUser = user;
    notifyListeners();
  }

  String? displayNameFor(UserProfile? profile) {
    final profileName = profile?.fullName?.trim();
    if (profileName != null && profileName.isNotEmpty) return profileName;
    final authName = _authUser?.displayName?.trim();
    if (authName != null && authName.isNotEmpty) return authName;
    return null;
  }

  String displayNameOr(UserProfile? profile, {String fallback = 'User'}) {
    return displayNameFor(profile) ?? fallback;
  }

  String emailOr(UserProfile? profile, {String fallback = '—'}) {
    final email = _authUser?.email.trim();
    if (email != null && email.isNotEmpty) return email;
    return fallback;
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? email,
  }) async {
    if (_isLoading) return false;
    _setLoading(true);
    clearMessages();
    try {
      await updateProfileUseCase(
        fullName: fullName,
        phoneNumber: phoneNumber,
        email: email,
      );
      final updated = authRepository.currentUser;
      if (updated != null) {
        _authUser = updated;
      }
      _successMessage = 'Profile updated successfully!';
      return true;
    } on AuthFailure catch (failure) {
      _errorMessage = failure.message;
      return false;
    } on DataFailure catch (failure) {
      _errorMessage = failure.message;
      return false;
    } catch (_) {
      _errorMessage = 'Could not update your profile. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (_isLoading) return false;
    if (newPassword != confirmPassword) {
      _errorMessage = 'New passwords do not match.';
      notifyListeners();
      return false;
    }
    if (newPassword.length < 6) {
      _errorMessage = 'New password must be at least 6 characters.';
      notifyListeners();
      return false;
    }
    _setLoading(true);
    clearMessages();
    try {
      await changePasswordUseCase(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      await _syncAppLockPassword(newPassword);
      _successMessage = 'Password changed successfully!';
      return true;
    } on AuthFailure catch (failure) {
      _errorMessage = failure.message;
      return false;
    } catch (_) {
      _errorMessage = 'Could not change your password. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// The dual-security App Lock mirrors the account password, so a successful
  /// change must re-hash it immediately (SHA-256) and store the new hash in
  /// secure storage. Otherwise the next app open would reject the new password.
  /// An App Lock that was never configured is left untouched.
  Future<void> _syncAppLockPassword(String newPassword) async {
    if (!appLockRepository.isEnabled) return;
    await appLockRepository.setPassword(newPassword);
  }

  Future<bool> updateCurrency(String currency) async {
    if (_isLoading) return false;
    _setLoading(true);
    clearMessages();
    try {
      await updateCurrencyUseCase(currency);
      _successMessage = 'Currency updated!';
      return true;
    } on DataFailure catch (failure) {
      _errorMessage = failure.message;
      return false;
    } catch (_) {
      _errorMessage = 'Could not update your currency. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
