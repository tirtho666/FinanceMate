import '../../domain/entities/app_user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../sources/remote/auth_remote_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteSource);

  final AuthRemoteSource _remoteSource;

  @override
  Stream<AppUser?> watchAuthState() {
    return _remoteSource.watchUser().map((user) => user?.toEntity());
  }

  @override
  AppUser? get currentUser => _remoteSource.currentUser?.toEntity();

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remoteSource.signIn(
        email: email,
        password: password,
      );
      return user.toEntity();
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure('Authentication failed. Please try again.');
    }
  }

  @override
  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remoteSource.signUp(
        fullName: fullName,
        email: email,
        password: password,
      );
      return user.toEntity();
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
        'Could not create your account. Please try again.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _remoteSource.signOut();
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure('Could not sign out. Please try again.');
    }
  }

  @override
  Future<void> updateDisplayName(String fullName) async {
    try {
      await _remoteSource.updateDisplayName(fullName);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure('Could not update your name.');
    }
  }

  @override
  Future<void> updateEmail(String email) async {
    try {
      await _remoteSource.updateEmail(email);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure('Could not update your email.');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _remoteSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
        'Could not change your password. Verify your current password and try again.',
      );
    }
  }

  @override
  Future<void> reloadUser() async {
    try {
      await _remoteSource.reloadUser();
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure('Could not refresh your account.');
    }
  }
}
