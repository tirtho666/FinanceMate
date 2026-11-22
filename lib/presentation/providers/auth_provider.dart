import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_palette.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/usecases/set_app_lock_password.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up_with_email.dart';
import '../../domain/usecases/watch_auth_state.dart';

enum AuthSubmitType { signIn, signUp }

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required this.signInWithEmail,
    required this.signUpWithEmail,
    required this.signOutUseCase,
    required this.setAppLockPassword,
    required WatchAuthState watchAuthState,
    AppUser? initialUser,
  }) : _user = initialUser {
    _authSubscription = watchAuthState().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  final SignInWithEmail signInWithEmail;
  final SignUpWithEmail signUpWithEmail;
  final SignOut signOutUseCase;
  final SetAppLockPassword setAppLockPassword;
  StreamSubscription<AppUser?>? _authSubscription;

  AppUser? _user;
  bool _isLoading = false;
  AuthSubmitType? _submitType;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isSigningIn => _isLoading && _submitType == AuthSubmitType.signIn;
  bool get isSigningUp => _isLoading && _submitType == AuthSubmitType.signUp;
  bool get isAuthenticated => _user != null;

  Future<void> signIn({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    final succeeded = await _runAuthAction(
      context: context,
      type: AuthSubmitType.signIn,
      action: () => signInWithEmail(email: email.trim(), password: password),
    );
    if (!succeeded || !context.mounted) return;
    await _configureAppLock(password);
    if (!context.mounted) return;
    _goToLock(context);
  }

  Future<void> signUp({
    required BuildContext context,
    required String fullName,
    required String email,
    required String password,
  }) async {
    final succeeded = await _runAuthAction(
      context: context,
      type: AuthSubmitType.signUp,
      action: () => signUpWithEmail(
        fullName: fullName,
        email: email.trim(),
        password: password,
      ),
    );
    if (!succeeded || !context.mounted) return;
    await _configureAppLock(password);
    if (!context.mounted) return;
    _goToLock(context);
  }

  Future<void> signOut(BuildContext context) async {
    try {
      _setLoading(true);
      await signOutUseCase();
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.auth,
        (route) => false,
      );
    } on AuthFailure catch (failure) {
      if (!context.mounted) return;
      _showError(context, failure.message);
    } catch (_) {
      if (!context.mounted) return;
      _showError(context, 'Could not sign out. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  /// The App Lock password mirrors the account password, so the freshly
  /// supplied password is hashed (SHA-256) and stored on device right away.
  Future<void> _configureAppLock(String password) async {
    if (password.isEmpty) return;
    try {
      await setAppLockPassword(password);
    } catch (_) {
      // The account is already authenticated; a keystore hiccup must not block
      // the user from reaching the app.
    }
  }

  Future<bool> _runAuthAction({
    required BuildContext context,
    required AuthSubmitType type,
    required Future<AppUser> Function() action,
  }) async {
    if (_isLoading) return false;
    _submitType = type;
    _setLoading(true);
    try {
      await action();
      return true;
    } on AuthFailure catch (failure) {
      if (context.mounted) {
        _showError(context, failure.message);
      }
      return false;
    } catch (_) {
      if (context.mounted) {
        _showError(context, 'Something went wrong. Please try again.');
      }
      return false;
    } finally {
      _submitType = null;
      _setLoading(false);
    }
  }

  void _goToLock(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.lock,
      (route) => false,
    );
  }

  void _showError(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppPalette.expense,
        ),
      );
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
