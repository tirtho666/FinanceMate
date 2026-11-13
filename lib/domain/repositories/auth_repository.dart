import '../entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> watchAuthState();

  AppUser? get currentUser;

  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> updateDisplayName(String fullName);

  Future<void> updateEmail(String email);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> reloadUser();
}
