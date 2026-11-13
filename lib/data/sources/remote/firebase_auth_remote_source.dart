import 'package:firebase_auth/firebase_auth.dart';

import '../../../domain/failures/auth_failure.dart';
import '../../models/app_user_model.dart';

class FirebaseAuthRemoteSource {
  FirebaseAuthRemoteSource(this._auth);

  final FirebaseAuth _auth;

  Stream<AppUserModel?> watchUser() {
    return _auth.authStateChanges().map(_mapUser);
  }

  AppUserModel? get currentUser => _mapUser(_auth.currentUser);

  Future<AppUserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _requireUser(credential.user);
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    }
  }

  Future<AppUserModel> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure(
          'Could not create your account. Please try again.',
        );
      }
      await user.updateDisplayName(fullName);
      await user.reload();
      return _requireUser(_auth.currentUser);
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> updateDisplayName(String fullName) async {
    try {
      final user = _requireCurrentFirebaseUser();
      await user.updateDisplayName(fullName);
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    } catch (_) {
      throw const AuthFailure('Could not update your display name.');
    }
  }

  Future<void> updateEmail(String email) async {
    try {
      final user = _requireCurrentFirebaseUser();
      await user.verifyBeforeUpdateEmail(email);
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    } catch (_) {
      throw const AuthFailure(
        'Could not update your email. Re-authenticate and try again.',
      );
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _requireCurrentFirebaseUser();
      final email = user.email;
      if (email == null || email.isEmpty) {
        throw const AuthFailure('No email associated with this account.');
      }
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    } catch (_) {
      throw const AuthFailure(
        'Could not change your password. Verify your current password and try again.',
      );
    }
  }

  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    } catch (_) {
      throw const AuthFailure('Could not refresh your account.');
    }
  }

  User _requireCurrentFirebaseUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure('You must be signed in.');
    }
    return user;
  }

  AppUserModel? _mapUser(User? user) {
    if (user == null) return null;
    return AppUserModel.fromFirebase(user);
  }

  AppUserModel _requireUser(User? user) {
    final model = _mapUser(user);
    if (model == null) {
      throw const AuthFailure('Authentication failed. Please try again.');
    }
    return model;
  }

  String _messageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'requires-recent-login':
        return 'Please sign out and back in before making this change.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}
